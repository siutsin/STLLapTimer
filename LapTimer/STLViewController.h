//
//  STLViewController.h
//  LapTimer
//
//  Created by Simon Li on 1/9/14.
//  Copyright (c) 2014 Simon Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface STLViewController : UITableViewController

// Config
@property (nonatomic) float cooldownPeriod;
@property (nonatomic) float sensitivity;

- (void)lap;
- (IBAction)didClickReset:(id)sender;

@end
