//
//  NSObjectRACSelectorSignalSpec.m
//  ReactiveCocoa
//
//  Created by Josh Abernathy on 3/18/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "RACTestObject.h"
#import "RACSubclassObject.h"

#import "NSObject+RACDeallocating.h"
#import "NSObject+RACPropertySubscribing.h"
#import "NSObject+RACSelectorSignal.h"
#import "RACCompoundDisposable.h"
#import "RACDisposable.h"
#import "RACSignal+Operations.h"
#import "RACSignal.h"
#import "RACTuple.h"

SpecBegin(NSObjectRACSelectorSignal)

describe(@"with an instance method", ^{
	it(@"should send the argument for each invocation", ^{
		RACSubclassObject *object = [[RACSubclassObject alloc] init];
		__block id value;
		[[object rac_signalForSelector:@selector(lifeIsGood:)] subscribeNext:^(RACTuple *x) {
			value = x.first;
		}];

		[object lifeIsGood:@42];

		expect(value).to.equal(@42);
	});

	it(@"should send completed on deallocation", ^{
		__block BOOL completed = NO;
		__block BOOL deallocated = NO;

		@autoreleasepool {
			RACSubclassObject *object __attribute__((objc_precise_lifetime)) = [[RACSubclassObject alloc] init];

			[object.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
				deallocated = YES;
			}]];

			[[object rac_signalForSelector:@selector(lifeIsGood:)] subscribeCompleted:^{
				completed = YES;
			}];

			expect(deallocated).to.beFalsy();
			expect(completed).to.beFalsy();
		}

		expect(deallocated).to.beTruthy();
		expect(completed).to.beTruthy();
	});

	it(@"should send the argument for each invocation to the instance's own signal", ^{
		RACSubclassObject *object1 = [[RACSubclassObject alloc] init];
		__block id value1;
		[[object1 rac_signalForSelector:@selector(lifeIsGood:)] subscribeNext:^(RACTuple *x) {
			value1 = x.first;
		}];

		RACSubclassObject *object2 = [[RACSubclassObject alloc] init];
		__block id value2;
		[[object2 rac_signalForSelector:@selector(lifeIsGood:)] subscribeNext:^(RACTuple *x) {
			value2 = x.first;
		}];

		[object1 lifeIsGood:@42];
		[object2 lifeIsGood:@"Carpe diem"];

		expect(value1).to.equal(@42);
		expect(value2).to.equal(@"Carpe diem");
	});

	it(@"should send multiple arguments for each invocation", ^{
		RACSubclassObject *object = [[RACSubclassObject alloc] init];
		__block id value1;
		__block id value2;
		[[object rac_signalForSelector:@selector(combineObjectValue:andSecondObjectValue:)] subscribeNext:^(RACTuple *x) {
			value1 = x.first;
			value2 = x.second;
		}];

		[object combineObjectValue:@42 andSecondObjectValue:@"foo"];

		expect(value1).to.equal(@42);
		expect(value2).to.equal(@"foo");
	});

	it(@"should send arguments for invocation of non-existant methods", ^{
		RACSubclassObject *object = [[RACSubclassObject alloc] init];
		__block id key;
		__block id value;
		[[object rac_signalForSelector:@selector(setObject:forKey:)] subscribeNext:^(RACTuple *x) {
			value = x.first;
			key = x.second;
		}];

		[object performSelector:@selector(setObject:forKey:) withObject:@YES withObject:@"Winner"];

		expect(value).to.equal(@YES);
		expect(key).to.equal(@"Winner");
	});

	it(@"should send arguments for invocation on previously KVO'd receiver", ^{
		RACSubclassObject *object = [[RACSubclassObject alloc] init];

		[RACAble(object, objectValue) replayLast];

		__block id key;
		__block id value;
		[[object rac_signalForSelector:@selector(setObjectValue:andSecondObjectValue:)] subscribeNext:^(RACTuple *x) {
			value = x.first;
			key = x.second;
		}];

		[object setObjectValue:@YES andSecondObjectValue:@"Winner"];

		expect(value).to.equal(@YES);
		expect(key).to.equal(@"Winner");
	});

	it(@"should send arguments for invocation when receiver is subsequently KVO'd", ^{
		RACSubclassObject *object = [[RACSubclassObject alloc] init];

		__block id key;
		__block id value;
		[[object rac_signalForSelector:@selector(setObjectValue:andSecondObjectValue:)] subscribeNext:^(RACTuple *x) {
			value = x.first;
			key = x.second;
		}];

		[RACAble(object, objectValue) replayLast];

		[object setObjectValue:@YES andSecondObjectValue:@"Winner"];

		expect(value).to.equal(@YES);
		expect(key).to.equal(@"Winner");
	});
});

describe(@"with a class method", ^{
	it(@"should send the argument for each invocation", ^{
		__block id value;
		[[RACSubclassObject rac_signalForSelector:@selector(lifeIsGood:)] subscribeNext:^(RACTuple *x) {
			value = x.first;
		}];

		[RACSubclassObject lifeIsGood:@42];

		expect(value).to.equal(@42);
	});
});

SpecEnd