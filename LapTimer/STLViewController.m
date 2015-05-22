//
//  STLViewController.m
//  LapTimer
//
//  Created by Simon Li on 1/9/14.
//  Copyright (c) 2014 Simon Li. All rights reserved.
//

#import "STLViewController.h"
#import <GPUImage.h>
#import <EXTScope.h>

@interface STLViewController ()

@property (weak, nonatomic) IBOutlet GPUImageView *filterView;
@property (weak, nonatomic) IBOutlet UILabel *titleTimerLabel;

@property (strong, nonatomic) GPUImageVideoCamera *videoCamera;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) NSMutableArray *lapTimeArray;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic, getter=isCoolingDown) BOOL cooldown;
@property (nonatomic) NSInteger lapCounter;

@end

@implementation STLViewController

#pragma mark - Default Variable

- (NSMutableArray*)lapTimeArray
{
    if (!_lapTimeArray) {
        _lapTimeArray = [NSMutableArray array];
    }
    return _lapTimeArray;
}

- (float)cooldownPeriod
{
    if (!_cooldownPeriod) {
        _cooldownPeriod = 2.0;
    }
    return _cooldownPeriod;
}

- (float)sensitivity
{
    if (!_sensitivity) {
        _sensitivity = 0.1;
    }
    return _sensitivity;
}

#pragma mark - Init

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self _setupTitleTimer];
    
    [self _setupMotionDetector];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.videoCamera stopCameraCapture];
    
    if (self.timer)
    {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    [super viewWillDisappear:animated];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.videoCamera.outputImageOrientation = [[UIApplication sharedApplication] statusBarOrientation];
}

#pragma mark - Interaction

- (IBAction)didClickReset:(id)sender
{
    [self.lapTimeArray removeAllObjects];
    [self.tableView reloadData];
    self.cooldown = NO;
    self.lapCounter = 0;
    self.startTime = nil;
    [self lap];
}

#pragma mark - Motion Detector

- (void)_setupMotionDetector
{
    if (self.videoCamera) return;
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset352x288 cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera.outputImageOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    GPUImageMotionDetector *filter = [[GPUImageMotionDetector alloc] init];
    @weakify(self)
    [(GPUImageMotionDetector *) filter setMotionDetectionBlock:^(CGPoint motionCentroid, CGFloat motionIntensity, CMTime frameTime)
    {
        @strongify(self)
        if (motionIntensity > self.sensitivity) [self lap];
    }];
    [self.videoCamera addTarget:filter];
    [self.videoCamera addTarget:self.filterView];
    [self.videoCamera startCameraCapture];
}

#pragma mark - Lap Timer

- (void)lap
{
    if (self.isCoolingDown) return;
    self.cooldown = YES;
    @weakify(self)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self)
        self.cooldown = NO;
    });
    
    if (!self.startTime)
    {
        self.startTime = [NSDate date];
    }
    else
    {
        self.lapCounter++;
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.startTime];
        self.startTime = [NSDate date];
        [self.lapTimeArray insertObject:[self _stringFromTimeInterval:interval] atIndex:0];
        @weakify(self)
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self)
            NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        });
    }
}

- (void)_setupTitleTimer
{
    if (self.timer) [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(_updateTimer:) userInfo:nil repeats:YES];
}

- (void)_updateTimer:(id)sender
{
    if (!self.startTime) return;
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.startTime];
    NSDictionary *timeUnits = [self _timeUnitsForInterval:interval];
    NSString *title = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",
                       (long)[timeUnits[@"minutes"] integerValue],
                       (long)[timeUnits[@"seconds"] integerValue],
                       (long)[timeUnits[@"centiseconds"] integerValue]];
    @weakify(self)
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self)
        [self.titleTimerLabel setText:title];
    });
}

- (NSString *)_stringFromTimeInterval:(NSTimeInterval)interval
{
    NSDictionary *timeUnits = [self _timeUnitsForInterval:interval];
    return [NSString stringWithFormat:@"Lap: %ld Time: %02ld:%02ld:%02ld",
            (long)self.lapCounter,
            (long)[timeUnits[@"minutes"] integerValue],
            (long)[timeUnits[@"seconds"] integerValue],
            (long)[timeUnits[@"centiseconds"] integerValue]];
}

- (NSDictionary*)_timeUnitsForInterval:(NSTimeInterval)interval
{
    double ti = (double)interval;
    NSInteger minutes = ((NSInteger)ti / 60) % 60;
    NSInteger seconds = (NSInteger)ti % 60;
    NSInteger centiseconds = roundf(fmod(ti, 1) * 100);
    return @{
             @"minutes" : @(minutes),
             @"seconds" : @(seconds),
             @"centiseconds" : @(centiseconds),
             };
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.lapTimeArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [cell.textLabel setText:self.lapTimeArray.count > 0 ? self.lapTimeArray[indexPath.row] : @""];
    return cell;
}

@end
