//
//  IntroPage2Controller.h
//  OneScream
//
//  Created by  Venus Kye on 11/5/15.
//  Copyright (c) 2015  Venus Kye. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IntroPage2Controller : UIViewController

@property (weak, nonatomic) UIViewController *m_parentController;
@property (weak, nonatomic) IBOutlet UIButton *m_btnBack;

- (IBAction)onBtnBack:(id)sender;
@end
