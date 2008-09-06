/**
 *  @file CIOObject.h
 *  @license MIT License (see LICENSE.txt)
 *  @date 6/17/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import <IOKit/IOKitLib.h>
#import "CocoaIO.h"

@interface CIOObject : NSObject {
	io_object_t mRawObject;
	int mAutoIORelease;
}
+ (id)wrap:(io_object_t)ro; //Wrap ro (select a suitable subclass and use it) and return with 1 retain. Does not ioAutorelease ro: you usually want to do this yourself. Objects are uniqueified over ro.
- (id)initWithRawObject:(io_object_t)ro; //Initialize a CIOObject. Do not select a suitable subclass. You shouldn't use this.
- (io_object_t)rawObject;
- (NSString*)ioClassName;
- (NSString*)ioSuperclassName;
- (NSArray*)ioClassPath; //The location in the class hierarchy, with element 0 the receiver's class name and the last element being the root class name.
- (BOOL)isEqualTo:(id)other;
- (int)ioRetainCount;
- (void)ioRetain;
- (void)ioRelease;
- (void)ioAutorelease; ///<Automatically release the object when the receiver is deallocated.
- (void)ioAutoretain; ///<Retain once, but set a marker so that the object is freed when the receiver is deallocated.
@end
