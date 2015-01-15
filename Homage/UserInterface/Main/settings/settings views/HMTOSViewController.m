//
//  HMTOSViewController.m
//  Homage
//
//  Created by Yoav Caspin on 3/28/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMTOSViewController.h"

@interface HMTOSViewController ()

@property (weak, nonatomic) IBOutlet UILabel *guiTitle;
@property (weak, nonatomic) IBOutlet UITextView *guiContent;

@end

@implementation HMTOSViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initContent];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - Content
-(void)initContent
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // The text file for this label.
    NSString *fPath = [[NSBundle mainBundle] pathForResource:@"LabelTOS" ofType:@"txt"];
    
    // Check if such file exists.
    if ([fm fileExistsAtPath:fPath]) {
        [self loadContentFromFileAtPath:fPath];
    }
}

-(void)loadContentFromFileAtPath:(NSString *)fPath
{
    NSString *text = [NSString stringWithContentsOfFile:fPath encoding:NSUTF8StringEncoding error:nil];
    if (text == nil) return;
    self.guiContent.text = text;
}

@end
