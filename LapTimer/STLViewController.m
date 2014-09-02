//
//  STLViewController.m
//  LapTimer
//
//  Created by Simon Li on 1/9/14.
//  Copyright (c) 2014 Simon Li. All rights reserved.
//

#import "STLViewController.h"
#import <GPUImage.h>

@interface STLViewController ()

@property (strong, nonatomic) GPUImageVideoCamera *videoCamera;
@property (strong, nonatomic) NSDate *startTime;
@property (strong, nonatomic) NSMutableArray *lapTimeArray;
@property (nonatomic, getter=isCoolingDown) BOOL cooldown;
@property (nonatomic) NSInteger lapCounter;

// Config
@property (nonatomic) float cooldownPeriod;

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

#pragma mark - Init

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupMotionDetector];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.videoCamera stopCameraCapture];
    [super viewWillDisappear:animated];
}

#pragma mark - Motion Detector

- (void)setupMotionDetector
{
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset352x288 cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    GPUImageMotionDetector *filter = [[GPUImageMotionDetector alloc] init];
    @weakify(self)
    [(GPUImageMotionDetector *) filter setMotionDetectionBlock:^(CGPoint motionCentroid, CGFloat motionIntensity, CMTime frameTime)
    {
        @strongify(self)
        if (motionIntensity > 0.1)
        {
            [self lap];
        }
    }];
    [self.videoCamera addTarget:filter];
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
        [self.lapTimeArray addObject:[self stringFromTimeInterval:interval]];
        @weakify(self)
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self)
            [self.tableView reloadData];
        });
        DLog(@"interval: %@", [self stringFromTimeInterval:interval]);
    }
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval
{
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"Lap: %ld Time: %02ld:%02ld:%02ld", (long)self.lapCounter, (long)hours, (long)minutes, (long)seconds];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.lapTimeArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *reversed = [[self.lapTimeArray reverseObjectEnumerator] allObjects];
    
    if (self.lapTimeArray.count > 0)
    {
        [cell.textLabel setText:reversed[indexPath.row]];
    }
    else
    {
        [cell.textLabel setText:@""];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //
}

@end
