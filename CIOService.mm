/**
 *  @file CIOService.m
 *  @license MIT License (see LICENSE.txt)
 *  @date 6/18/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import "CIOService.h"
#import "CocoaIO.h"
#import <IOKit/IOMessage.h>

NSString* CIOServiceChangedNotification = @"CIOServiceChangedNotification";

void CIOServiceInterestCallback(
	void *			refcon,
	io_service_t	service,
	uint32_t		messageType,
	void *			messageArgument) {
		if (messageType==kIOMessageServiceBusyStateChange) {
			[(CIOService*)refcon didChangeValueForKey:@"busyness"];
		}
		NSDictionary* ui = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedInt:messageType], @"type",
			[NSValue valueWithPointer:messageArgument], @"arg",
			nil];
		#ifdef CIODebug
		NSLog(@"GIntrstNot: %@ %u %p", refcon, messageType, messageArgument);
		#endif
		[[NSNotificationCenter defaultCenter] postNotificationName:CIOServiceChangedNotification object:(id)refcon userInfo:ui];
}

NSString* CIOGeneral  = @"General";
NSString* CIOBusyness = @"Busyness";
NSString* CIOPower    = @"Power";
NSString* CIOPriority = @"Priority";
NSString* CIOPlatform = @"Platform";
const char* ioNotTypeFromName(NSString* name) {
	if ([name isEqualToString:CIOGeneral]) return kIOGeneralInterest;
	if ([name isEqualToString:CIOBusyness]) return kIOBusyInterest;
	if ([name isEqualToString:CIOPower]) return kIOAppPowerStateInterest;
	if ([name isEqualToString:CIOPriority]) return kIOPriorityPowerStateInterest;
	if ([name isEqualToString:CIOPlatform]) return kIOPlatformDeviceMessageKey;
	NSLog(@"Unknown key");
	return kIOGeneralInterest;
}


@implementation CIOService
#define mService() (io_service_t)mRawObject

- (id)initWithRawObject:(io_object_t)obj {
	if (![super initWithRawObject:obj]) return nil;
	mNotifications = new CIOServiceNotificationVec();
	return self;
}

- (void)dealloc {
	CIOServiceNotificationVec::iterator it=mNotifications->begin(), e=mNotifications->end();
	for (; it!=e; it++) {
		IOObjectRelease((*it).obj);
		[(*it).type release];
	}
	delete mNotifications;
	[self closeConnection];
	[super dealloc];
}

- (void)startWatching:(NSString*)notificationType {
	CIOServiceNotificationVec::iterator it=mNotifications->begin(), e=mNotifications->end();
	for (; it!=e; it++)
		if ([(*it).type isEqualToString:notificationType]) return;

	io_object_t not_obj;
	kern_return_t r = IOServiceAddInterestNotification([CIO() notificationPort], mService(), ioNotTypeFromName(notificationType), CIOServiceInterestCallback, self, &not_obj);
	if (r!=kIOReturnSuccess) {NSLog(@"Could not start watching %@ because %u", self, r); return;}
	CIOServiceNotification n = {not_obj, [notificationType retain]};
	mNotifications->push_back(n);
}

- (unsigned)busyness {
	uint32_t st;
	kern_return_t r = IOServiceGetBusyState(mService(), &st);
	if (r!=kIOReturnSuccess) NSLog(@"!!!");
	return st;
}

- (BOOL)waitForSeconds:(unsigned int)secs nanosecs:(int)nsecs {
	mach_timespec_t ts; ts.tv_sec = secs; ts.tv_nsec = nsecs;
	kern_return_t r = IOServiceWaitQuiet(mService(), &ts);
	if (r==kIOReturnTimeout) return NO;
	if (r==kIOReturnSuccess) return YES;
	NSLog(@"!!!");
	return NO;
}

- (kern_return_t)scanForNewDevices {
	kern_return_t r = IOServiceRequestProbe(mService(), 0);
	if (r==kIOReturnUnsupported) NSLog(@"The service %@ does not support scanning for new devices. It probably does that automatically.", self);
	return r;
}

- (void)addObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
	if ([keyPath isEqualToString:@"busyness"]) [self startWatching:CIOBusyness];
	[super addObserver:anObserver forKeyPath:keyPath options:options context:context];
}

- (io_connect_t)connectionOfType:(long)type {
	if (mConnection) {
		NSLog(@"Closing old connection for IOService %@", self);
		[self closeConnection];
	}
	io_connect_t ret;
	kern_return_t r = IOServiceOpen(mService(), mach_task_self(), type, &ret);
	if (r!=kIOReturnSuccess) {
		NSLog(@"Unable to open connection for reason %p", r);
		return NULL;
	}
	return mConnection=ret;
}

- (void)closeConnection {
	if (mConnection) IOConnectRelease(mConnection);
	mConnection = NULL;
}

@end
