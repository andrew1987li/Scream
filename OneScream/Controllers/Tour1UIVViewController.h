//
//  Tour1UIVViewController.h
//  OneScream
//
//  Created by Usman Ali on 28/01/2016.
//  Copyright © 2016  Venus Kye. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Tour1UIVViewController : UIViewController
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomUp;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *height;
@property (weak, nonatomic) IBOutlet UIButton *back;
@property (nonatomic) BOOL fromMenu;
@property (weak, nonatomic) IBOutlet UIPageControl *control;

@end
