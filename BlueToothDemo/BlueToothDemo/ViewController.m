//
//  ViewController.m
//  BlueToothDemo
//
//  Created by 孙扬 on 2017/2/7.
//  Copyright © 2017年 ProgrammerSunny. All rights reserved.
//

#import "ViewController.h"
#import "BlueToothController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = YES;
    
}

- (IBAction)becomePeropheral:(id)sender {
    
}

- (IBAction)connectPeropheral:(id)sender {
    [self.navigationController pushViewController:[[BlueToothController alloc] init] animated:YES];
}
@end
