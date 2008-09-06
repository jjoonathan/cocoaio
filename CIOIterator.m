/**
 *  @file CIOIterator.m
 *  @license MIT License (see LICENSE.txt)
 *  @date 6/17/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import "CIOIterator.h"


@implementation CIOIterator

- (NSArray*)allObjects {
	return CIOIteratorAllObjs((io_iterator_t)mRawObject);
}

@end

NSArray* CIOIteratorAllObjs(io_iterator_t ittr) {
	IOIteratorReset(ittr);
	NSMutableArray* a = [NSMutableArray new];
	io_object_t o;
	while (o = IOIteratorNext(ittr)) {
		id oco = [CIOObject wrap:o];
		[a addObject:oco];
		[oco ioAutorelease];
	}
	return [a autorelease];
}

NSArray* CIOIteratorStealObjs(io_iterator_t ittr) {
	NSArray* ret = CIOIteratorAllObjs(ittr);
	IOObjectRelease(ittr);
	return ret;
}