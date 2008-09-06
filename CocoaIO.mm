/**
 *  @file CocoaIO.m
 *  @license MIT License (see LICENSE.txt)
 *  @date 6/17/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#include <vector>
#import "CocoaIO.h"
#import "CIORegistryEntry.h"
#import "CIOIterator.h"

CocoaIO* gCocoaIOSharedInstance = nil;
NSString* CIOMatchingNotification = @"CIOMatchingNotification";
typedef struct {io_iterator_t it; NSDictionary* d; NSString* act;} not_t;
typedef std::vector<not_t> not_vec_t;
typedef std::vector<CFRunLoopSourceRef> not_src_vec_t;


void CIOServiceMatchingCallback(void* refcon, io_iterator_t it) {
	NSArray* objs = CIOIteratorAllObjs(it);
	NSEnumerator* e = [objs objectEnumerator];
	id o; while (o=[e nextObject]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:CIOMatchingNotification object:o userInfo:nil];
	}
}
	


@implementation CocoaIO
#define mNots() ((not_vec_t*)mNotifications)
//#define mNotSrcs() ((not_vec_t*)mNotifications)

extern "C" CocoaIO* CIO() {
	if (!gCocoaIOSharedInstance)
		gCocoaIOSharedInstance = [CocoaIO new];
	return gCocoaIOSharedInstance;
}

+ (CocoaIO*)sharedInstance {
	return CIO();
}

- (id)init {
	if (![super init]) return nil;
	mDefaultPlane = @"Service";
	mNotifications = (void*)(new not_vec_t());
	//mNotificationSources = (void*)(new not_src_vec_t());
	return self;
}

///@warning doesn't remove the installed run loop source(s). This hopefully shouldn't be too big of a problem...
- (void)dealloc {
	//Terminate each notification individually.
	not_vec_t::iterator it=mNots()->begin(), e=mNots()->end();
	for (; it!=e; it++) {
		IOObjectRelease((*it).it);
		[(*it).d release];
		[(*it).act release];
	}
	delete mNots();
	
	if (mNotificationPort) IONotificationPortDestroy(mNotificationPort);
	[super dealloc];
}

- (mach_port_t)masterPort {
	if (!mMasterPort) {
		kern_return_t r = IOMasterPort(MACH_PORT_NULL, &mMasterPort);
		if (r!=kIOReturnSuccess) {
			NSLog(@"Master port creation failed");
			mMasterPort = MACH_PORT_NULL;
		}
	}
	return mMasterPort;
}

- (IONotificationPortRef)notificationPort {
	if (!mNotificationPort) {
		mNotificationPort = IONotificationPortCreate([self masterPort]);
		[self checkForNotificationsOnThisThread];
	}
	return mNotificationPort;
}

- (void)checkForNotificationsOnThisThread {
	CFRunLoopSourceRef src = IONotificationPortGetRunLoopSource([self notificationPort]);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), src, kCFRunLoopCommonModes);
	CFRelease(src);
}

- (CIORegistryEntry*)registryRoot {
	io_registry_entry_t r = IORegistryGetRootEntry([self masterPort]);
	CIORegistryEntry* re = [[CIORegistryEntry alloc] initWithRawObject:r];
	[re ioAutorelease]; [re autorelease];
	return re;
}

- (NSString*)currentDefaultPlane {
	return mDefaultPlane;
}

- (void)setCurrentDefaultPlane:(NSString*)newPlane {
	mDefaultPlane = newPlane;
}

- (NSArray*)servicesForName:(NSString*)name {return [self servicesMatching:CIOMatchName(name)];}
- (NSArray*)servicesForClass:(NSString*)name {return [self servicesMatching:CIOMatchClass(name)];}
- (NSArray*)servicesForBSDName:(NSString*)name {return [self servicesMatching:CIOMatchBSDName(name)];}
- (NSArray*)servicesForFWPath:(NSString*)name {return [self servicesMatching:CIOMatchFWPath(name)];}
- (NSArray*)servicesMatching:(NSDictionary*)matchingDict {
	io_iterator_t it;
	CFRetain(matchingDict); //It will get CFReleased in IOServiceGetMatchingServices
	kern_return_t r = IOServiceGetMatchingServices([self masterPort], (CFDictionaryRef)matchingDict, &it);
	if (r!=kIOReturnSuccess) {
		NSLog(@"Matching dict %@ failed", matchingDict);
		return nil;
	}
	return CIOIteratorStealObjs(it);
}

const char* constForAction(NSString* action) {
	if ([action isEqualToString:@"Published"]) return kIOPublishNotification;
	if ([action isEqualToString:@"FirstPublished"]) return kIOFirstPublishNotification;
	if ([action isEqualToString:@"Matched"]) return kIOMatchedNotification;
	if ([action isEqualToString:@"FirstMatched"]) return kIOFirstMatchNotification;
	if ([action isEqualToString:@"Terminated"]) return kIOTerminatedNotification;
	NSLog(@"Unknown action '%@' should be one of Published, FirstPublished, Matched, FirstMatched, Terminated. Assuming @\"Published\".", action);
	return kIOPublishNotification;
}

- (void)notifyWhenMatches:(NSDictionary*)match_dict are:(NSString*)action {
	//Don't add twice if we are already looking
	not_vec_t::iterator it=mNots()->begin(), e=mNots()->end();
	for (; it!=e; it++)
		if ([(*it).d isEqualToDictionary:match_dict]&&[(*it).act isEqualToString:action]) return;
	
	not_t new_not;
	CFRetain(match_dict); //Gets released in IOServiceAddMatchingNotification
	kern_return_t r = IOServiceAddMatchingNotification([self notificationPort], constForAction(action), (CFDictionaryRef)match_dict, CIOServiceMatchingCallback, self, &(new_not.it));
	if (r!=kIOReturnSuccess) {
		NSLog(@"Failed to notify for %@ because %p", match_dict, r);
		return;
	}
	CIOServiceMatchingCallback(self, new_not.it);
	new_not.d=[match_dict copy];
	new_not.act=[action copy];
	mNots()->push_back(new_not);
}

- (void)stopNotifiyWhenMatches:(NSDictionary*)match_dict are:(NSString*)action {
	not_vec_t::iterator it=mNots()->begin(), e=mNots()->end();
	for (; it!=e; it++)
		if ([(*it).d isEqualToDictionary:match_dict]) {
			IOObjectRelease((*it).it);
			[(*it).d release];
			[(*it).act release];
			mNots()->erase(it);
		}
	NSLog(@"Couldn't find notification dict %@ to remove", match_dict);
}

@end



@implementation NSString (CocoaIO)

- (NSString*)ioSuperclass {
	return [(id)IOObjectCopySuperclassForClass((CFStringRef)self) autorelease];
}

- (NSString*)ioBundleIdentifier {
	return [(id)IOObjectCopyBundleIdentifierForClass((CFStringRef)self) autorelease];
}

@end



#ifdef CIODebug
@implementation NSObject (EasyDescription)
- (NSString*)de {return [self description];}
@end
#endif



extern "C" NSMutableDictionary* CIOMatchClass(NSString* serviceClassName) {return [(id)IOServiceMatching([serviceClassName UTF8String]) autorelease];}
extern "C" NSMutableDictionary* CIOMatchName(NSString* serviceName) {return [(id)IOServiceNameMatching([serviceName UTF8String]) autorelease];}
extern "C" NSMutableDictionary* CIOMatchBSDName(NSString* bsdName) {return [(id)IOBSDNameMatching([CIO() masterPort], 0, [bsdName UTF8String]) autorelease];}
extern "C" NSMutableDictionary* CIOMatchFWPath(NSString* firmwarePath) {return [(id)IOOpenFirmwarePathMatching([CIO() masterPort], 0, [firmwarePath UTF8String]) autorelease];}
