//
//  TYGCDANRMonitor.m
//  PrismMonitorDemo
//
//  Created by tany on 2017/4/7.
//  Copyright © 2017年 tany. All rights reserved.
//

#import "TYGCDANRMonitor.h"
#import "__BSBacktraceLogger.h"

@interface TYGCDANRMonitor ()

@property (nonatomic, assign) BOOL isRunning;

@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, assign) NSInteger timeOutCount;

@property (nonatomic, assign) NSTimeInterval timeOutInterval;

@property (nonatomic, assign) NSInteger curTimeOutCount;

@end

@implementation TYGCDANRMonitor

- (instancetype)initWithTimeOutInterval:(NSTimeInterval)timeOutInterval timeOutCount:(NSInteger)timeOutCount {
    if (self = [super init]) {
        _timeOutInterval = timeOutInterval;
        _timeOutCount = timeOutCount;
        _queue = dispatch_queue_create("com.YeBlueColor.TYRunLoopANRMonitor", NULL);
    }
    return self;
}

- (instancetype)init {
    if (self = [self initWithTimeOutInterval:0.2 timeOutCount:5]) {
    }
    return self;
}

- (void)start {
    if (_isRunning) {
        return;
    }
    _isRunning = YES;
    
    _semaphore = dispatch_semaphore_create(1);
    
     dispatch_async(_queue, ^{
         while(_isRunning) {
             long st = dispatch_semaphore_wait(_semaphore, dispatch_time(DISPATCH_TIME_NOW, _timeOutInterval*1000*NSEC_PER_MSEC));
             
             if (st != 0) {
                 if (!_isRunning) {
                     _curTimeOutCount = 0;
                     _semaphore = nil;
                     return;
                 }
                 //NSLog(@"_curTimeOutCount %ld",_curTimeOutCount);
                 if (++_curTimeOutCount < _timeOutCount) {
                     continue;
                 }
                 
                [self handleANRTimeOut];
                 dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
             }
             _curTimeOutCount = 1;
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 dispatch_semaphore_signal(_semaphore);
             });
             
             [NSThread sleepForTimeInterval:_timeOutInterval];
         }
     });
    
}

- (void)stop {
    if (!_isRunning) {
        return;
    }
    _isRunning = NO;
    _curTimeOutCount = 0;
}

#pragma mark - handle timeout

- (void)handleANRTimeOut {
    TYANRLogInfo *logInfo = [[TYANRLogInfo alloc]init];
    logInfo.content = [__BSBacktraceLogger bs_backtraceOfAllThread];
    logInfo.date = [NSDate date];
    logInfo.time = [logInfo.date timeIntervalSince1970];
    if ([_delegate respondsToSelector:@selector(ANRMonitor:didRecievedANRTimeOutInfo:)]) {
        [_delegate ANRMonitor:self didRecievedANRTimeOutInfo:logInfo];
    }
}

- (void)dealloc {
    [self stop];
}

@end
