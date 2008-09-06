/**
 *  @file CIORegistryEntry.m
 *  @license MIT License (see LICENSE.txt)
 *  @date 6/17/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import "CIORegistryEntry.h"
#import "CIOIterator.h"
#import "CocoaIO.h"

NSString* CIOServicePlane		=  	@"Service";
NSString* CIOPowerPlane			=   @"Power";
NSString* CIODeviceTreePlane	=   @"Device";
NSString* CIOAudioPlane			=   @"Audio";
NSString* CIOFireWirePlane		=   @"FireWire";
NSString* CIOUSBPlane			=   @"USB";
static IOOptionBits emptyOptionBits = 0;


@implementation CIORegistryEntry
#define mEntry() (io_registry_entry_t)mRawObject

#ifdef CIODebug
- (NSDictionary*)pr {return [self properties];}
#endif

const char* planeForName(NSString* name) {
	if ([name isEqualToString:CIOServicePlane]) return kIOServicePlane;
	if ([name isEqualToString:CIOPowerPlane]) return kIOPowerPlane;
	if ([name isEqualToString:CIODeviceTreePlane]) return kIODeviceTreePlane;
	if ([name isEqualToString:CIOAudioPlane]) return kIOAudioPlane;
	if ([name isEqualToString:CIOFireWirePlane]) return kIOFireWirePlane;
	if ([name isEqualToString:CIOUSBPlane]) return kIOUSBPlane;
	NSLog(@"Unknown plane %@. Using service plane.");
	return kIOServicePlane;
}

- (NSArray*)c {return [self children];}
- (NSArray*)ls {return [[self children] valueForKey:@"name"];}
- (NSArray*)children {return [self childrenInPlane:[CIO() currentDefaultPlane]];}
- (NSArray*)childrenInPlane:(NSString*)plane {
	io_iterator_t it;
	kern_return_t s = IORegistryEntryCreateIterator(mEntry(), planeForName(plane), emptyOptionBits, &it);
	if (s!=kIOReturnSuccess) return nil;
	return CIOIteratorStealObjs(it);
}

/*- (NSString*)name {
	io_name_t ret;
	kern_return_t r = IORegistryEntryGetName(mEntry(), ret);
	if (r!=kIOReturnSuccess) {NSLog(@"Name buffer overflow."); return nil;}
	return [NSString stringWithUTF8String:ret];
}*/

- (NSString*)name {return [self nameInPlane:[CIO() currentDefaultPlane]];}
- (NSString*)nameInPlane:(NSString*)plane {
	io_name_t ret;
	kern_return_t r = IORegistryEntryGetNameInPlane(mEntry(), planeForName(plane), ret);
	if (r!=kIOReturnSuccess) {NSLog(@"Name buffer overflow."); return nil;}
	return [NSString stringWithUTF8String:ret];
}


- (NSString*)path {return [self pathInPlane:[CIO() currentDefaultPlane]];}
- (NSString*)pathInPlane:(NSString*)plane {
	io_string_t ret;
	kern_return_t r = IORegistryEntryGetPath(mEntry(), planeForName(plane), ret);
	if (r!=kIOReturnSuccess) {NSLog(@"Path buffer overflow."); return nil;}
	return [NSString stringWithUTF8String:ret];
}

- (NSDictionary*)properties {
	CFMutableDictionaryRef ret;
	kern_return_t r = IORegistryEntryCreateCFProperties(mEntry(), &ret, kCFAllocatorDefault, emptyOptionBits);
	if (r!=kIOReturnSuccess) {NSLog(@"Property creation failed."); return nil;}
	return [(NSDictionary*)ret autorelease];
}

- (id)propertyNamed:(NSString*)name {
	CFTypeRef ret = IORegistryEntryCreateCFProperty(mEntry(), (CFStringRef)name, kCFAllocatorDefault, emptyOptionBits);
	return [(NSObject*)ret autorelease];
}

- (void)setValue:(id)v forPropertyNamed:(NSString*)pname {
	kern_return_t r = IORegistryEntrySetCFProperty(mEntry(), (CFStringRef)pname, (CFTypeRef)v);
	if (r!=kIOReturnSuccess) NSLog(@"Unable to set property \"%@\"", pname);
}

- (NSString*)description {
	return [NSString stringWithFormat:@"#<CIORegistryEntry class='%@' name='%@'>", [self ioClassName], [self name]];
}

@end
