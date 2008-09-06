/**
 *  @file CIOObject.m
 *  @license MIT License (see LICENSE.txt)
 *  @date 6/17/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import "CIOObject.h"
#import "CIOIterator.h"
#import "CIORegistryEntry.h"
#import "CIOService.h"
#import "CIOUSBDevice.h"

static CFMutableDictionaryRef existing_objects = NULL;


@implementation CIOObject

+ (id)wrap:(io_object_t)ro {
	if (!existing_objects)
		existing_objects = CFDictionaryCreateMutable(NULL, 0, NULL, NULL); 
	id existing_obj;
	BOOL exists = CFDictionaryGetValueIfPresent(existing_objects, (void*)ro, (const void**)&existing_obj);
	if (exists) return [existing_obj retain];
	
	static NSDictionary* wrapper_map = nil;
	if (!wrapper_map) wrapper_map = [[NSDictionary alloc] initWithObjectsAndKeys:
		[CIOIterator class], @"IOIterator",
		[CIORegistryEntry class], @"IORegistryEntry",
		[CIOService class], @"IOService",
		[CIOUSBDevice class], @"IOUSBDevice",
		nil];
	NSString* cname = (NSString*)IOObjectCopyClass(ro);
	while (cname) {
		Class c = [wrapper_map objectForKey:cname];
		NSString* new_cname = (NSString*)IOObjectCopySuperclassForClass((CFStringRef)cname);
		[cname release];
		cname = new_cname;
		if (c) {
			id new_obj = [[c alloc] initWithRawObject:ro];
			CFDictionaryAddValue(existing_objects, (void*)ro, new_obj);
			return new_obj;
		}
	}
	id new_obj = [[self alloc] initWithRawObject:ro];
	CFDictionaryAddValue(existing_objects, (void*)ro, new_obj);
	return new_obj;
}

- (id)initWithRawObject:(io_object_t)ro {
	if (![super init]) return nil;
	mRawObject = ro;
	return self;
}

- (void)dealloc {
	int i; for (i=0; i<mAutoIORelease; i++) IOObjectRelease(mRawObject);
	CFDictionaryRemoveValue(existing_objects, (void*)mRawObject);
	[super dealloc];
}

- (io_object_t)rawObject {
	return mRawObject;
}

- (NSString*)ioClassName {
	return [(NSString*)IOObjectCopyClass(mRawObject) autorelease];
}

- (NSString*)ioSuperclassName {
	return [(NSString*)IOObjectCopySuperclassForClass((CFStringRef)[self ioClassName]) autorelease];
}

- (NSArray*)ioClassPath {
	NSString* c = [self ioClassName];
	NSMutableArray* ret = [NSMutableArray arrayWithObject:c];
	while (c) {
		[ret addObject:c];
		c = (NSString*)IOObjectCopySuperclassForClass((CFStringRef)c);
		[c autorelease];
	}
	return ret;
}

- (BOOL)isEqualTo:(id)other {
	return IOObjectIsEqualTo(mRawObject, [other rawObject]);
}

- (int)ioRetainCount {
	return IOObjectGetRetainCount(mRawObject);
}

- (void)ioRetain {
	IOObjectRetain(mRawObject);
}

- (void)ioRelease {
	IOObjectRelease(mRawObject);
}

- (void)ioAutorelease {
	mAutoIORelease++;
}

- (void)ioAutoretain {
	[self ioRetain];
	[self ioAutorelease];
}

- (BOOL)ioIsKindOfClass:(NSString*)cname {
	return IOObjectConformsTo(mRawObject, [[self ioClassName] UTF8String]) ? YES : NO;
}

- (NSString*)description {
	return [NSString stringWithFormat:@"#<CIOObject class='%@'>", [self ioClassName]];
}

@end
