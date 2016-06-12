//
//  FrequentAddressViewController.m
//  OneScream
//
//  Created by sohail khan on 20/03/2016.
//  Copyright © 2016  Venus Kye. All rights reserved.
//

#import "FrequentAddressViewController.h"
#import "SaveFrequentedAddressesViewController.h"
#import "Parse/Parse.h"
#import "UserAddress.h"
#import "ThankyouController.h"

@interface FrequentAddressViewController ()
{

    __weak IBOutlet UIPageControl *pageControl;
    __weak IBOutlet UIView *addressViewContainer;
    
    __weak IBOutlet UIButton *homeAddressButton;
    __weak IBOutlet UIView *homeAddressViewContainer;
    __weak IBOutlet UIView *homeAddressView;

    
    __weak IBOutlet UIButton *workAddressButton;
    __weak IBOutlet UIView *workAddressViewContainer;
    __weak IBOutlet UIView *workAddressView;

    
    __weak IBOutlet UIButton *frequentedAddressButton;
    __weak IBOutlet UIView *frequentedAddressViewContainer;
    __weak IBOutlet UIView *frequentedAddressView;

    
    
    __weak IBOutlet UIButton *saveAddressButton;
    
    __weak IBOutlet UIImageView *homeAddressImageView;
    __weak IBOutlet NSLayoutConstraint *homeAddressContainerViewHeight;

    __weak IBOutlet NSLayoutConstraint *workAddressContainerViewYPostion;
    __weak IBOutlet NSLayoutConstraint *frequentedAddressContainerViewYPosition;
    
    __weak IBOutlet UILabel *homeAddressLabel;
    __weak IBOutlet UILabel *workAddressLabel;
    __weak IBOutlet UILabel *frequentedAddressLabel;
    
    __weak IBOutlet UILabel *headerAddressLabel;

    
    
    
    
    
}

@end

@implementation FrequentAddressViewController


#pragma mark - View


-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    
    PFUser *user = [PFUser currentUser];
    if (user[HOME_ADDRESS_PARSE_COLOUMN] == nil){
        homeAddressButton.hidden = false;
        homeAddressView.hidden = true;
        workAddressContainerViewYPostion.constant = - (homeAddressView.bounds.size.height - homeAddressButton.frame.size.height) - 1;
    }else{
        
        UserAddress *homeAddress = user[HOME_ADDRESS_PARSE_COLOUMN];
        homeAddressView.hidden = false;
        homeAddressButton.hidden = true;
        saveAddressButton.hidden = false;
        headerAddressLabel.hidden = true;
        
        workAddressContainerViewYPostion.constant =  - 1;
        homeAddressLabel.text = [NSString stringWithFormat:@"%@,\n%@,\n%@,%@,%@",homeAddress.streetAddress1,homeAddress.streetAddress2,homeAddress.city,homeAddress.state,homeAddress.postal];
        
        
        
    }
    if (user[WORK_ADDRESS_PARSE_COLOUMN] == nil){
        workAddressButton.hidden = false;
        workAddressView.hidden = true;
        
        frequentedAddressContainerViewYPosition.constant = - (workAddressView.bounds.size.height - workAddressButton.bounds.size.height) - 1;
        
    }else{
        workAddressView.hidden = false;
        workAddressButton.hidden = true;
        headerAddressLabel.hidden = true;
        
        frequentedAddressContainerViewYPosition.constant = - 1;
        
        
        UserAddress *workAddress = user[WORK_ADDRESS_PARSE_COLOUMN];
        
        workAddressLabel.text = [NSString stringWithFormat:@"%@,\n%@,\n%@,%@,%@",workAddress.streetAddress1,workAddress.streetAddress2,workAddress.city,workAddress.state,workAddress.postal];
        
        
        
        
    }
    
    if (user[FREQUENTED_ADDRESS_PARSE_COLOUMN] == nil){
        frequentedAddressButton.hidden = false;
        frequentedAddressView.hidden = true;
        
    }else{
        frequentedAddressView.hidden = false;
        frequentedAddressButton.hidden = true;
        headerAddressLabel.hidden = true;
        
        
        UserAddress *frequentedAddress = user[FREQUENTED_ADDRESS_PARSE_COLOUMN];
        
        frequentedAddressLabel.text = [NSString stringWithFormat:@"%@,\n%@,\n%@,%@,%@",frequentedAddress.streetAddress1,frequentedAddress.streetAddress2,frequentedAddress.city,frequentedAddress.state,frequentedAddress.postal];
        
        
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    homeAddressViewContainer.clipsToBounds = YES;
    workAddressViewContainer.clipsToBounds = YES;

    
    UIColor *borderColor = [UIColor colorWithRed:234.0/255.0 green:234.0/255.0 blue:234.0/255.0 alpha:1.0];
    homeAddressButton.layer.cornerRadius = 3.0;
    homeAddressButton.layer.borderColor = borderColor.CGColor;
    homeAddressButton.layer.borderWidth = 1;
    
    
    workAddressButton.layer.cornerRadius = 3.0;
    workAddressButton.layer.borderColor = borderColor.CGColor;
    workAddressButton.layer.borderWidth = 1;
    
    frequentedAddressButton.layer.cornerRadius = 3.0;
    frequentedAddressButton.layer.borderColor = borderColor.CGColor;
    frequentedAddressButton.layer.borderWidth = 1;
    
    
    /*PFUser *user = [PFUser currentUser];
    [user removeObjectForKey:HOME_ADDRESS_PARSE_COLOUMN];
    [user removeObjectForKey:WORK_ADDRESS_PARSE_COLOUMN];
    [user removeObjectForKey:FREQUENTED_ADDRESS_PARSE_COLOUMN];*/
    
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [addressViewContainer setNeedsLayout];
    [addressViewContainer layoutIfNeeded];

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - IBActions
- (IBAction)addHomeAddressButtonPressed:(id)sender {
    
    [self performSegueWithIdentifier:@"SaveFrequentedAddressesViewController" sender:sender];
}

- (IBAction)addWorkaddressButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"SaveFrequentedAddressesViewController" sender:sender];

}

- (IBAction)addFrequentedAddressButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"SaveFrequentedAddressesViewController" sender:sender];

}
- (IBAction)saveAddressButtonPressed:(id)sender {
    //[self.navigationController popToRootViewControllerAnimated:NO];
    ThankyouController *nextScr = (ThankyouController *) [self.storyboard instantiateViewControllerWithIdentifier:@"ThankyouController"];
    nextScr.fromMenu = NO;
    nextScr.hidebtn = YES;
    [self.navigationController pushViewController:nextScr animated:YES];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    SaveFrequentedAddressesViewController *dVC = (SaveFrequentedAddressesViewController*) segue.destinationViewController  ;
    if (sender == homeAddressButton){
        dVC.address_type = HOME;
    }else if (sender == workAddressButton){
        dVC.address_type = WORK;
    }else if (sender == frequentedAddressButton) {
        dVC.address_type = FREQUENT;
    }
    
    
}


@end
