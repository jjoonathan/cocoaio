/**
 *  @file CIOIterator.h
 *  @license MIT License (see LICENSE.txt)
 *  @date 6/17/08.
 *  @author Jonathan deWerd
 *  @copyright Copyright 2008 Jonathan deWerd. This file is distributed under the MIT license (see accompanying file for details).
 */
#import "CIOObject.h"

@interface CIOIterator : CIOObject {
}
- (NSArray*)allObjects;
@end

CIO_EXTERN_C NSArray* CIOIteratorAllObjs(io_iterator_t ittr); ///<Gets the objects of ittr, but doesn't release ittr
CIO_EXTERN_C NSArray* CIOIteratorStealObjs(io_iterator_t ittr); ///<Gets the objects of ittr, then releases ittr
