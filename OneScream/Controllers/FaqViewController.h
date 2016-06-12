//
//  FaqViewController.h
//  OneScream
//
//  Created by Usman Ali on 02/02/2016.
//  Copyright © 2016  Venus Kye. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FaqViewController : UIViewController <UITabBarDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *table_view;

@end
