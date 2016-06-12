//
//  UpdateFrequentedAddressesViewController.m
//  OneScream
//
//  Created by sohail khan on 25/03/2016.
//  Copyright © 2016  Venus Kye. All rights reserved.
//

#import "UpdateFrequentedAddressesViewController.h"
#import "Parse/Parse.h"
#import "UserAddress.h"
#import "SaveFrequentedAddressesViewController.h"
#import "MBProgressHUD.h"

@interface UpdateFrequentedAddressesViewController ()
{

    __weak IBOutlet UIButton *backButton;

    __weak IBOutlet UIView *homeAddressView;
    __weak IBOutlet UIView *homeAddressContainerView;
    
    __weak IBOutlet UILabel *homeAddressLabel;
    
    
    
    __weak IBOutlet UIView *workAddressContainerView;
    __weak IBOutlet UIButton *addWorkAddressButton;
    __weak IBOutlet UIView *workAddressView;
    
    __weak IBOutlet UILabel *workAddressLabel;
    
    
    
    __weak IBOutlet UIView *frequentedAddressContainerView;
    __weak IBOutlet UIButton *addFrequentedAddressButton;
    __weak IBOutlet UIView *frequentedAddressView;
    
    __weak IBOutlet UILabel *frequentedAddressLabel;
    
    
    __weak IBOutlet NSLayoutConstraint *workAddressContainerViewYPostion;
    __weak IBOutlet NSLayoutConstraint *frequentedAddressContainerViewYPosition;
    
    
    
}
@end

@implementation UpdateFrequentedAddressesViewController

#pragma mark - View


-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    PFUser *user = [PFUser currentUser];
    UserAddress *homeAddress = user[HOME_ADDRESS_PARSE_COLOUMN];
    if (homeAddress != nil){
        homeAddressView.hidden = false;
        homeAddressLabel.text = [NSString stringWithFormat:@"%@,\n%@,\n%@,%@,%@",homeAddress.streetAddress1,homeAddress.streetAddress2,homeAddress.city,homeAddress.state,homeAddress.postal];
    }
    
    //addWorkAddressButton.hidden = false;
    //workAddressView.hidden = true;
    if (user[WORK_ADDRESS_PARSE_COLOUMN] == nil){
        addWorkAddressButton.hidden = false;
        workAddressView.hidden = true;
        
        frequentedAddressContainerViewYPosition.constant = - (workAddressView.bounds.size.height - addWorkAddressButton.bounds.size.height) - 1;
        
    }else{
        workAddressView.hidden = false;
        addWorkAddressButton.hidden = true;
        
        frequentedAddressContainerViewYPosition.constant = - 1;
        UserAddress *workAddress = user[WORK_ADDRESS_PARSE_COLOUMN];
        workAddressLabel.text = [NSString stringWithFormat:@"%@,\n%@,\n%@,%@,%@",workAddress.streetAddress1,workAddress.streetAddress2,workAddress.city,workAddress.state,workAddress.postal];
        
    }
    
    if (user[FREQUENTED_ADDRESS_PARSE_COLOUMN] == nil){
        addFrequentedAddressButton.hidden = false;
        frequentedAddressView.hidden = true;
        
    }else{
        frequentedAddressView.hidden = false;
        addFrequentedAddressButton.hidden = true;
        UserAddress *frequentedAddress = user[FREQUENTED_ADDRESS_PARSE_COLOUMN];
        frequentedAddressLabel.text = [NSString stringWithFormat:@"%@,\n%@,\n%@,%@,%@",frequentedAddress.streetAddress1,frequentedAddress.streetAddress2,frequentedAddress.city,frequentedAddress.state,frequentedAddress.postal];
    }
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    homeAddressContainerView.clipsToBounds = YES;
    workAddressContainerView.clipsToBounds = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    
    UIColor *borderColor = [UIColor colorWithRed:234.0/255.0 green:234.0/255.0 blue:234.0/255.0 alpha:1.0];

    
    
    addWorkAddressButton.layer.cornerRadius = 3.0;
    addWorkAddressButton.layer.borderColor = borderColor.CGColor;
    addWorkAddressButton.layer.borderWidth = 1;
    
    addFrequentedAddressButton.layer.cornerRadius = 3.0;
    addFrequentedAddressButton.layer.borderColor = borderColor.CGColor;
    addFrequentedAddressButton.layer.borderWidth = 1;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:true];
}

- (IBAction)editHomeAddressButtonPressed:(id)sender {
    SaveFrequentedAddressesViewController *nextScr = (SaveFrequentedAddressesViewController *) [self.storyboard instantiateViewControllerWithIdentifier:@"SaveFrequentedAddressesViewController"];
    nextScr.isForUpdateAddress = true;
    nextScr.address_type = HOME;
    [self.navigationController pushViewController:nextScr animated:YES];
}
- (IBAction)addWorkAddressButtonPressed:(id)sender {
    
    SaveFrequentedAddressesViewController *nextScr = (SaveFrequentedAddressesViewController *) [self.storyboard instantiateViewControllerWithIdentifier:@"SaveFrequentedAddressesViewController"];
    nextScr.isForUpdateAddress = false;
    nextScr.address_type = WORK;
    [self.navigationController pushViewController:nextScr animated:YES];
}
- (IBAction)editWorkAddressButtonPressed:(id)sender {
    
    SaveFrequentedAddressesViewController *nextScr = (SaveFrequentedAddressesViewController *) [self.storyboard instantiateViewControllerWithIdentifier:@"SaveFrequentedAddressesViewController"];
    nextScr.isForUpdateAddress = true;
    nextScr.address_type = WORK;
    [self.navigationController pushViewController:nextScr animated:YES];
}
- (IBAction)deleteWorkAddressButtonPressed:(id)sender {
    
    UpdateFrequentedAddressesViewController *wSelf = self;
    [MBProgressHUD showHUDAddedTo:self.view animated:true];
     PFUser *user = [PFUser currentUser];
    UserAddress *address = user[WORK_ADDRESS_PARSE_COLOUMN];
    [address deleteInBackgroundWithBlock:^(BOOL success, NSError * error){
    }];
    [user removeObjectForKey:WORK_ADDRESS_PARSE_COLOUMN];
    [user saveInBackgroundWithBlock:^(BOOL success, NSError * error){
        [MBProgressHUD hideHUDForView:wSelf.view animated:true];
        
    }];

}
- (IBAction)editFrequentedAddressButtonPressed:(id)sender {
    SaveFrequentedAddressesViewController *nextScr = (SaveFrequentedAddressesViewController *) [self.storyboard instantiateViewControllerWithIdentifier:@"SaveFrequentedAddressesViewController"];
    nextScr.isForUpdateAddress = true;
    nextScr.address_type = FREQUENT;
    [self.navigationController pushViewController:nextScr animated:YES];
}

- (IBAction)deleteFrequentedAddressButtonPressed:(id)sender {
    
    UpdateFrequentedAddressesViewController *wSelf = self;
    [MBProgressHUD showHUDAddedTo:self.view animated:true];
    PFUser *user = [PFUser currentUser];
    UserAddress *address = user[FREQUENTED_ADDRESS_PARSE_COLOUMN];
    [address deleteInBackgroundWithBlock:^(BOOL success, NSError * error){
    }];
    [user removeObjectForKey:FREQUENTED_ADDRESS_PARSE_COLOUMN];
    [user saveInBackgroundWithBlock:^(BOOL success, NSError * error){
        [MBProgressHUD hideHUDForView:wSelf.view animated:true];

    }];
    
}

- (IBAction)addFrequentedAddressesButtonPressed:(id)sender {
    
    SaveFrequentedAddressesViewController *nextScr = (SaveFrequentedAddressesViewController *) [self.storyboard instantiateViewControllerWithIdentifier:@"SaveFrequentedAddressesViewController"];
    nextScr.isForUpdateAddress = false;
    nextScr.address_type = FREQUENT;
    [self.navigationController pushViewController:nextScr animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
