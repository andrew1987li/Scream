//
//  HomeController.m
//  OneScream
//
//  Created by  Anwar Almojarkesh on 9/11/15.
//  Copyright (c) 2015  Anwar Almojarkesh. All rights reserved.
//
//  View Controller Class for Home Screen
//

#import "HomeController.h"
#import "UIViewController+ECSlidingViewController.h"
#import "FirstPageController.h"
#import "HowToController.h"
#import "SettingsController.h"
#import "DetectedScreamController.h"
#import "EMGLocationManager.h"
#import "UpgradeController.h"
#import "WiFisController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioServices.h>
#import <AVFoundation/AVAudioSession.h>
#import "AskToJoinController.h"
#import <Parse/Parse.h>

#include "EngineMgr.h"
#import "FrequentAddressViewController.h"

@interface HomeController () {
    int m_nShineRequestCnt;
}

@property AVAudioPlayer *myAudioPlayer;
@property NSString* soundObjectId;
@property BOOL isFirst;
@property BOOL isOpenedAudio;

@end

@implementation HomeController

#define ALERT_VIEW_ASK_TO_JOIN 10002
#define ALERT_VIEW_ASK_TO_REG_WIFI 10003

/** WIFI Checking period */
#define WIFI_CHECKING_PERIOD 5

@synthesize m_lblTitle;
@synthesize m_imgDetectingStatus;
@synthesize m_imgDetectingStatus1;
@synthesize m_lblDetectingStatus;
@synthesize m_btnDetect;


- (void) gotoFrequentedAddressController {
    

    [self.navigationController setNavigationBarHidden:true animated:false];
        FrequentAddressViewController *nextScr = (FrequentAddressViewController *) [self.storyboard instantiateViewControllerWithIdentifier:@"FrequentAddressViewController"];
        [self.navigationController pushViewController:nextScr animated:NO];
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    m_nShineRequestCnt = 0;
    
    self.slidingViewController.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGestureTapping | ECSlidingViewControllerAnchoredGesturePanning;
    self.slidingViewController.customAnchoredGestures = @[];
    self.slidingViewController.anchorRightPeekAmount  = 100.0;
    [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    UISwipeGestureRecognizer *swipeRecognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(btLeftMenuClick:)];
    swipeRecognizerRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRecognizerRight];

    // Do any additional setup after loading the view, typically from a nib.
    m_nPastTimes = 0;
    m_bOpenedAudio = false;
    m_lFirstDateTime = 0;
    
    self.myAudioPlayer = nil;
    
    self.soundObjectId = nil;
    
    self.isFirst=NO;
    
    m_bNewScreenLoaded = false;
    
    [self loadFirstDateTime];
    m_ignoredWIFIs = [[NSMutableArray alloc] init];
    
    [EngineMgr sharedInstance].isNeedToSubscribe = NO;

    
    
    // Login Checking With Parse User Information
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        NSLog(@"in current user");
        
        [currentUser fetchInBackground];
        
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        currentInstallation.channels = @[[EngineMgr convertEmailToChannelStr:[currentUser email]]];
        [currentInstallation saveInBackground];
        BOOL show = [[NSUserDefaults standardUserDefaults]  boolForKey:@"subscribeORTrail"];
        if (currentUser[HOME_ADDRESS_PARSE_COLOUMN] == nil || show ==  false){
        
            [self gotoFrequentedAddressController];
        }
//        
//        [self initEngine];
    } else {
        // if this is first launch after the app was downloaded, then open first page
        self.isFirst = YES;
        m_bNewScreenLoaded = true;
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"]) {
            [self gotoFirstPageController:YES];
        } else {
            [self gotoFirstPageController:NO];
        }
    }
    

}

- (IBAction)btLeftMenuClick:(id)sender {
    
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [AppEventTracker trackScreenWithName:@"Listening"];

}

- (void)viewWillAppear:(BOOL)animated {
    // Hide navigation bar of Home screen
    [self.navigationController setNavigationBarHidden:YES];
    
    [EngineMgr sharedInstance].isDetecting = [[NSUserDefaults standardUserDefaults]boolForKey:@"isScreamListening"];
    
    // Updating UI elements for detecting
    [self updateUIForDetectingStatus];
    
    if(self.isFirst){
        self.isFirst = NO;
    }
    
    if ([EngineMgr sharedInstance].isNeedToSubscribe) {
        [EngineMgr sharedInstance].isNeedToSubscribe = NO;
        [self gotoUpgradeController];
        
        m_bNewScreenLoaded = true;
    } else if ([EngineMgr sharedInstance].isAutoStartProtecting) {
        [EngineMgr sharedInstance].isAutoStartProtecting = NO;
        [self switchDetecting];
        
        m_bNewScreenLoaded = true;
    }
    
    if (!m_bNewScreenLoaded) {
        if ([self checkCurrentWIFIAskable]) {
            [self showAlertForWIFI];
        }
    }

}


#pragma mark - Event Listener

- (IBAction)onSettings:(id)sender {
    [self gotoSettingsController];
}

- (BOOL) isUserExpired {
    // Check if the user is expired
    PFUser *user = [PFUser currentUser];
    NSDate *date_expiry = user[@"expiry_date"];
    NSDate *now = [NSDate date];
    if (date_expiry == nil)
        date_expiry = now;

    int seconds = [date_expiry timeIntervalSinceDate:now];
    if (seconds >= 0) {
        return NO;
    }
    return YES;
}

- (IBAction)onBtnDetect:(id)sender {
    
    [self switchDetecting];
}

- (void)switchDetecting {
    [EngineMgr sharedInstance].isDetecting = ![EngineMgr sharedInstance].isDetecting;
    
    [self updateUIForDetectingStatus];
    
    if ([[EngineMgr sharedInstance] isDetecting])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startDetectedProcess) name:@"scream_detected" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopDetectedProcess) name:@"detection_confirmed" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLoadedFromBackground) name:@"from_background" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopDetectedProcessWithFalse) name:@"detection_false" object:nil];
        
        [EngineMgr sharedInstance].shouldBackgroundRunning = YES;
        
        [[EMGLocationManager sharedInstance] stopLocationUpdate];
        [[EMGLocationManager sharedInstance] startLocationUpdate];
        
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"isScreamListening"];
        [[NSUserDefaults standardUserDefaults]synchronize];
        
        [self initEngine];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
        [dic setObject:[PFUser currentUser].email forKey:@"User Email"];
        [AppEventTracker trackEvnetWithName:@"Start Detecting" withData:dic];
        
    }
    else{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"scream_detected" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"detection_confirmed" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"detection_false" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"from_background" object:nil];
        
        [EngineMgr sharedInstance].shouldBackgroundRunning = NO;
        
        [[EMGLocationManager sharedInstance] stopLocationUpdate];
        
        [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"isScreamListening"];
        [[NSUserDefaults standardUserDefaults]synchronize];
        
//        [self showAlert:@"You are not protected. Don't forget to turn one scream back on!" alertTag:0];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
        if ([PFUser currentUser] != nil){
            [dic setObject:[PFUser currentUser].email forKey:@"User Email"];
            [AppEventTracker trackEvnetWithName:@"Stop Detecting" withData:dic];
        }

        [self terminateEngine];
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == ALERT_VIEW_ASK_TO_JOIN)
    {
        if(buttonIndex == 0) {
            [self gotoUpgradeController];
        } else {
            [self switchDetecting];
        }
    } else if (alertView.tag == ALERT_VIEW_ASK_TO_REG_WIFI) {
        
        if (buttonIndex == 0) {
            [m_ignoredWIFIs addObject:m_strCurWiFiID];
            
            [self gotoWiFisController];
        } else {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSString *strKey = [NSString stringWithFormat:@"ignore_%@", m_strCurWiFiID];
            
            NSDate *now = [NSDate date];
            NSTimeInterval timeStampNow = [now timeIntervalSince1970];
            [userDefaults setInteger:(long)timeStampNow forKey:strKey];
            [userDefaults synchronize];
        }
    }
}

#pragma mark - self UI functions

- (void) updateUIForDetectingStatus {
    if ([[EngineMgr sharedInstance] isDetecting]) {
        // now protecting
        [m_imgDetectingStatus setHidden:NO];
        [self stopViewShine:m_imgDetectingStatus];
        [m_imgDetectingStatus setImage:[UIImage imageNamed:@"ic_moon_home"]];
        [self makeViewSmall];
        [m_lblTitle setText:@"Not to Worry"];
        [m_lblDetectingStatus setText:@"You are being protected by One Scream"];
        [m_btnDetect setImage:[UIImage imageNamed:@"ic_pause"] forState:UIControlStateNormal];
    } else {
        // now not protecting
        [m_imgDetectingStatus setHidden:YES];
        [self stopViewShine:m_imgDetectingStatus];
        //[m_imgDetectingStatus setImage:[UIImage imageNamed:@"ic_planet"]];
        [m_imgDetectingStatus1 setImage:[UIImage imageNamed:@"ic_planet"]];
        [m_imgDetectingStatus1 setHidden:NO];
        [m_lblTitle setText:@"Standing By"];
        [m_lblDetectingStatus setText:@"Press play and we will listen"];
        [m_btnDetect setImage:[UIImage imageNamed:@"ic_play"] forState:UIControlStateNormal];
    }
}

- (void) gotoHowToController {
    HowToController *nextScr = (HowToController *) [self.storyboard instantiateViewControllerWithIdentifier:@"HowToController"];
    [self.navigationController pushViewController:nextScr animated:NO];
}

- (void) gotoFirstPageController:(BOOL)bFirstStart {
    FirstPageController *nextScr = (FirstPageController *) [self.storyboard instantiateViewControllerWithIdentifier:@"FirstPageController"];
    nextScr.m_bFirst = bFirstStart;
    [self.navigationController pushViewController:nextScr animated:NO];
}

- (void) gotoSettingsController {
    SettingsController *nextScr = (SettingsController *) [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsController"];
    [self.navigationController pushViewController:nextScr animated:YES];
}

- (void) gotoUpgradeController {
    UpgradeController *nextScr = (UpgradeController *) [self.storyboard instantiateViewControllerWithIdentifier:@"UpgradeController"];
    [self.navigationController pushViewController:nextScr animated:YES];
}

- (void) gotoAskToJoinController {
    AskToJoinController *nextScr = (AskToJoinController *)[self.storyboard instantiateViewControllerWithIdentifier:@"AskToJoinController"];
    [self.navigationController pushViewController:nextScr animated:YES];
}

- (void) gotoDetectedController {
    DetectedScreamController *nextScr = (DetectedScreamController *) [self.storyboard instantiateViewControllerWithIdentifier:@"DetectedScreamController"];
    [self.navigationController pushViewController:nextScr animated:YES];
}

- (void) gotoWiFisController {
    WiFisController *nextScr = (WiFisController *) [self.storyboard instantiateViewControllerWithIdentifier:@"WiFisController"];
    nextScr.m_bSelectAddress = true;
    [self.navigationController pushViewController:nextScr animated:YES];
}


#pragma mark - Audio Processing
- (void) initAudioSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    BOOL  success =[session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    if (!success) {
        
        // Exit early
        return ;
    }

    NSError* error;
    success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    if (![[EngineMgr sharedInstance] isSessionObserverAdded]) {
    
        [center addObserverForName:AVAudioSessionRouteChangeNotification
                            object:session
                             queue:nil
                        usingBlock:^(NSNotification *notification)
         {
             // NSLog(@"notiname=%@", notification.name);
             UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
             // AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
             
             // printf("Route change:\n");
             switch (reasonValue) {
                 case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
                     NSLog(@"     NewDeviceAvailable");
                     break;
                 case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
                     NSLog(@"     OldDeviceUnavailable");
                     break;
                 case AVAudioSessionRouteChangeReasonCategoryChange:
                     NSLog(@"     CategoryChange");
                     break;
                 case AVAudioSessionRouteChangeReasonOverride:
                     NSLog(@"     Override");
                     break;
                 case AVAudioSessionRouteChangeReasonWakeFromSleep:
                     NSLog(@"     WakeFromSleep");
                     break;
                 case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
                     NSLog(@"     NoSuitableRouteForCategory");
                     break;
                 default:
                     NSLog(@"     ReasonUnknown %d", reasonValue);
             }
             
             // NSLog(@"Previous route disc= %@", routeDescription);
             [[EngineMgr sharedInstance] propListener:&reasonValue inDataSize:sizeof(reasonValue)];
         }];
        
        [center addObserverForName:AVAudioSessionInterruptionNotification
                            object:session
                             queue:nil
                        usingBlock:^(NSNotification *notification)
         {
             NSLog(@"interrupt notiname=%@", notification.name);
             UInt8 interuptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
             
             switch (interuptionType) {
                 case AVAudioSessionInterruptionTypeBegan:
                     NSLog(@"Audio Session Interruption case started.");
                     //                 if (pController != nullptr && pController->isOpened())
                     //                 {
                     //                     pController->close();
                     //                 }
                     break;
                 case AVAudioSessionInterruptionTypeEnded:
                 {
                     NSLog(@"Audio Session Interruption case ended.");
                     //                    pController->open(g_audioInfo, audioCallback);
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"restartEngine" object:nil];
                 }
                     break;
                 default:
                     NSLog(@"Audio Session Interruption Notification case default %d", interuptionType);
                     break;
             }
         }];
        
        [EngineMgr sharedInstance].isSessionObserverAdded = YES;
    }

    //[[AVAudioSession sharedInstance] setDelegate:self];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];

    AVAudioSessionPortDescription *port = [AVAudioSession sharedInstance].availableInputs[0];
    
    // Using Back Microphone of iPhone if it is exist [Sergei added 2015.12.12]
//    for (AVAudioSessionDataSourceDescription *source in port.dataSources) {
//        if ([source.dataSourceName isEqualToString:@"Back"]) {
//            [port setPreferredDataSource:source error:nil];
//        }
//    }
    
    Float64 sampleRate = [[EngineMgr sharedInstance] getSampleRate];
    float bufLen = [[EngineMgr sharedInstance] getBufDuration];
    [session setPreferredSampleRate:sampleRate error:nil];
    [session setPreferredIOBufferDuration:bufLen error:nil];
    Float64 sampleRateCur =[session sampleRate];
    
    
    float bufLenCur = [session IOBufferDuration];
    
    if (bufLen != bufLenCur || sampleRate != sampleRateCur) {
        fprintf(stderr, "ERROR is mismatch [%f:%f][%f:%f]\n", bufLen, bufLenCur, sampleRate, sampleRateCur);
    }
    
}

- (void) terminateAudioSession {
   
    [[AVAudioSession sharedInstance] setActive:NO error: nil];
}

#pragma mark - Engine functions and notification receivers

/**
 * Init engine functions and register notification receivers
 */

-(void)initEngine {
    if ([[EngineMgr sharedInstance] isEngineRunning])
        return;
    
    self.isOpenedAudio = NO;
    
    // Init Engine
    
    [self initAudioSession];
    [[EngineMgr sharedInstance] initEngine];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self detectingSounds];
    });
    
    self.isFirst=YES;
    
    // Register notification receivers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartEngine) name:@"restartEngine" object:nil];
}

-(void)terminateEngine {
    if (![[EngineMgr sharedInstance] isEngineRunning]) {
        return;
    }
    
    [EngineMgr sharedInstance].isDetecting = NO;
    
    [[EngineMgr sharedInstance] terminateEngine];
    
    [self terminateAudioSession];
}

- (void)restartEngine {
    [[EngineMgr sharedInstance] closeAudio];
    
    [self initAudioSession];
    
    [[EngineMgr sharedInstance] restartEngine];
}

- (void) detectingSounds
{
    static int times = 0;
    
    while(YES)
    {
        if (times % 120000 == 50) {
            // Check every 5 hours
            [self checkCurrentWIFIAndRecord];
        }
        
        times++;
        if (times > 240000) {
            times = 0;
        }

        
        if(![[EngineMgr sharedInstance] isEngineRunning])
            break;
        
        NSLog(@"Reading %d %@", times, [[AVAudioSession sharedInstance] secondaryAudioShouldBeSilencedHint] ? @"other" : @"me");
        
        while ([[EngineMgr sharedInstance] readData])
        {
            if(![[EngineMgr sharedInstance] isEngineRunning])
                break;
            
            BOOL bDetected = [[EngineMgr sharedInstance] detectScream];
            if (bDetected)
            {
                int nSoundDetectedType = [[EngineMgr sharedInstance] getDetectedSoundType];
                
                if (![[EngineMgr sharedInstance] isBackground]) {
                    [self updateScreamDetected:nSoundDetectedType];
                } else {
                    NSString *szNotifcation = @"Scream Detected\nYou have 12 seconds to cancel\nSwipe left to cancel";
                    UILocalNotification *localNotification = [[UILocalNotification alloc]init];
                    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
                    localNotification.alertBody = szNotifcation;
                    localNotification.alertTitle = @"OneScream";
                    localNotification.alertAction = @"left to cancel";
                    localNotification.category = @"ACTIONABLE";
                    localNotification.repeatInterval=0;
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                    NSLog(@"Background Mode");
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"scream_detected" object:nil];
                }
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSString *strFilePath = [self saveHistory];
                    [self saveHistoryOnParse:strFilePath];
                });
            }
        }
        usleep(150000);
    }
}

- (void) updateScreamDetected:(int)soundType
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self sendPushMessage];
        
        [self gotoDetectedController];
    });
}

/**
 * Send Push message using Parse Framework
 */
- (void)sendPushMessage {
    
    PFUser *currentUser = [PFUser currentUser];
    if (false)
    {
        // Find devices associated with these users
        NSString *deviceToken = [[NSUserDefaults standardUserDefaults]objectForKey:@"deviceToken"];
        NSString *channel = [EngineMgr convertEmailToChannelStr:[currentUser email]];
        PFQuery *pushQuery = [PFInstallation query];
        [pushQuery whereKey:@"channels" equalTo:channel];
        [pushQuery whereKey:@"deviceToken" notEqualTo:deviceToken];
        
        NSString *senderEmail  = [[NSUserDefaults standardUserDefaults]objectForKey:@"email"];
        
        UIDevice *device = [UIDevice currentDevice];
        NSString  *currentDeviceId = [[device identifierForVendor]UUIDString];
        NSString* strNotifyType = @"One Scream";
        
        // Send push notification to query
        PFPush *push = [[PFPush alloc] init];
        [push setQuery:pushQuery]; // Set our Installation query
        NSDictionary * postDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%@,%d,0",currentDeviceId,0],[NSString stringWithFormat:@"%@- From %@",strNotifyType,senderEmail], @"android.intent.action.PUSH_STATE", nil]
                                                                    forKeys:[NSArray arrayWithObjects:@"message", @"alert",@"action", nil]];
        
        [push setData:postDictionary];
        [push sendPushInBackground];
    }
    
    NSDateFormatter *formatter,*TimeFormatter;
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/MMM/yyyy"];
    
    TimeFormatter = [[NSDateFormatter alloc] init];
    [TimeFormatter setDateFormat:@"HH:mm"];
    
    NSString* dateString = [formatter stringFromDate:[NSDate date]];
    NSString* timeString = [TimeFormatter stringFromDate:[NSDate date]];
    
    PFObject *PFHistory = [PFObject objectWithClassName:@"userNotification"];
    PFHistory[@"userId"] = [[NSUserDefaults standardUserDefaults]objectForKey:@"userObjectId"];
    PFHistory[@"userName"] = [[PFUser currentUser] email];
    PFHistory[@"userType"] = @"2";
    PFHistory[@"soundType"] = @"ONE_SCREAM";
    
    PFHistory[@"eventDescription"] = @"One Scream";
    PFHistory[@"date"] = dateString;
    PFHistory[@"time"] = timeString;
    PFHistory[@"os"] = @"iOS";
    PFHistory[@"status"] = @"Not Yet";
    
    self.soundObjectId = @"";
    [PFHistory saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            //[self.view setUserInteractionEnabled:true];
            self.soundObjectId = PFHistory.objectId;
            // The object has been saved.
        }   else {
            // [self.view setUserInteractionEnabled:true];
            // There was a problem, check error.description
            self.soundObjectId = @"";
        }
        [[EngineMgr sharedInstance] setSoundObjectId:self.soundObjectId];
    }];
}

- (void)setTorch:(BOOL)status {
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        [device lockForConfiguration:nil];
        if ( [device hasTorch] ) {
            if ( status ) {
                [device setTorchMode:AVCaptureTorchModeOn];
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
            }
        }
        [device unlockForConfiguration];
        
    }
}

- (void)timerFiredForFlash:(id)userInfo
{
    while(m_nPastTimes <= (POLICE_SIREN_PERIODS / 100)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if([[NSUserDefaults standardUserDefaults]boolForKey:@"flashLightAlert"])
            {
                // flash
                if (m_nPastTimes % 8 == 4)
                    [self setTorch:NO];
                else if (m_nPastTimes % 8 == 0)
                    [self setTorch:YES];
            }

            if (m_nPastTimes % 10 == 0)
            {
                // vibrate
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            }
        });
        
        m_nPastTimes++;
        usleep(100000);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.myAudioPlayer != nil) {
            if ([self.myAudioPlayer isPlaying]) {
                [self.myAudioPlayer stop];
            }
            self.myAudioPlayer = nil;
        }
        
        if (m_bOpenedAudio) {
            [[EngineMgr sharedInstance] playAudio];
            
            m_bOpenedAudio = false;
        }
        
        [self setTorch:NO];

        [[EngineMgr sharedInstance] setEnginePause:NO];
    });
}

- (void)startDetectedProcess
{
    [[EngineMgr sharedInstance] setEnginePause:YES];

    if (self.myAudioPlayer != nil) {
        if ([self.myAudioPlayer isPlaying]) {
            [self.myAudioPlayer stop];
        }
        self.myAudioPlayer = nil;
    }
    
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"policesiren" ofType:@"mp3"];
    NSURL* fileURL = [[NSURL alloc] initFileURLWithPath:soundFilePath];
    self.myAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    self.myAudioPlayer.numberOfLoops = -1;
    [self.myAudioPlayer play];
    

    m_bOpenedAudio = [[EngineMgr sharedInstance] pauseAudio] == YES ? true : false;
    
    m_nPastTimes = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self timerFiredForFlash:nil];
    });
    
    [self sendPushMessage];
}

- (void)onLoadedFromBackground {
    
    if (m_nShineRequestCnt == 0 && [[EngineMgr sharedInstance] isDetecting]) {
        [self makeViewShine:m_imgDetectingStatus];
    }
    
    [self stopDetectedProcess];
}

- (void)stopDetectedProcess
{
    m_nPastTimes = (POLICE_SIREN_PERIODS / 100) + 1;
    
    [self updateHistory:@"Confirmed"];
}

- (void)stopDetectedProcessWithFalse {
    m_nPastTimes = (POLICE_SIREN_PERIODS / 100) + 1;
    
    [[EngineMgr sharedInstance] processFalseDetect];
    
    [self updateHistory:@"False"];
}


- (void)updateHistory:(NSString *)status
{
    if (self.soundObjectId == nil || self.soundObjectId.length == 0)
        return;
    
    PFQuery *query = [PFQuery queryWithClassName:@"userNotification"];
    
    // Retrieve the object by id
    [query getObjectInBackgroundWithId:self.soundObjectId
                                 block:^(PFObject *PFNotify, NSError *error) {
                                     // Now let's update it with some new data. In this case, only cheatMode and score
                                     // will get sent to the cloud. playerName hasn't changed.
                                     PFNotify[@"status"] = status;
                                     [PFNotify saveInBackground];
                                 }];
    
}

- (void)showAlert:(NSString *)message alertTag:(NSInteger *)tag
{
    UIAlertView *myalert = [[UIAlertView alloc]initWithTitle:@"One Scream" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    myalert.tag = (NSInteger)tag;
    [myalert show];
}

- (void)showAlertForWIFI
{
    NSString *message = @"Current connected WIFI has been regularly connected every day. Please register this.";
    UIAlertView *myalert = [[UIAlertView alloc]initWithTitle:@"One Scream" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: @"Not now", nil];
    myalert.tag = (NSInteger)ALERT_VIEW_ASK_TO_REG_WIFI;
    [myalert show];
}


#pragma mark - Checking WIFI

- (void) loadFirstDateTime {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    m_lFirstDateTime = [userDefaults integerForKey:@"first_date_time"];
    if (m_lFirstDateTime == 0) {
        NSDate* date = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
        NSDateComponents *comps = [calendar components:unitFlags fromDate:date];
        comps.hour = 0;
        comps.minute = 0;
        comps.second = 0;
        NSDate *newDate = [calendar dateFromComponents:comps];
        
        NSTimeInterval secs = [newDate timeIntervalSince1970];
        m_lFirstDateTime = (long) secs;
        [userDefaults setInteger:m_lFirstDateTime forKey:@"first_date_time"];
        [userDefaults synchronize];
    }
}

- (bool) checkCurrentWIFIAskable {
    NSString *strWiFiID = [EngineMgr currentWifiSSID];
    

    if (strWiFiID == nil || [strWiFiID length] == 0) {
        // Nothing connected
        return false;
    }
    
    int idx = [[EngineMgr sharedInstance] getWiFiItemIdx:strWiFiID];
    if (idx >= 0) {
        // already registered
        return false;
    }
    
    // Check if this is ignored WIFI
    for (int i = 0; i < [m_ignoredWIFIs count]; i++) {
        if ([strWiFiID isEqualToString:[m_ignoredWIFIs objectAtIndex:i]]) {
            return false;
        }
    }
    
    NSDate *now = [NSDate date];
    NSTimeInterval timeStampNow = [now timeIntervalSince1970];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *strKey = [NSString stringWithFormat:@"ignore_%@", strWiFiID];
    long ignoreTimestamp = [userDefaults integerForKey:strKey];
    if (((long)timeStampNow - ignoreTimestamp) < 3600 * 24 )
        return false;

    if (m_lFirstDateTime == 0) {
        m_lFirstDateTime = [userDefaults integerForKey:@"first_date_time"];
    }

    long daysFromStart = ((long)timeStampNow - m_lFirstDateTime) / (3600 * 24);
    
    int nCount = 0;
    for (int i = (int)daysFromStart; i > daysFromStart - WIFI_CHECKING_PERIOD; i--) {
        if (i < 0)
            break;
        NSString *strKey = [NSString stringWithFormat:@"%d_%@", i, strWiFiID];
        if ([userDefaults boolForKey:strKey]) {
            nCount++;
        }
    }
    
    if (nCount == WIFI_CHECKING_PERIOD) {
        m_strCurWiFiID = strWiFiID;
        return true;
    }
    
    return false;
}

- (void) checkCurrentWIFIAndRecord {
    NSString *strWiFiID = [EngineMgr currentWifiSSID];
    
    
    if (strWiFiID == nil || [strWiFiID length] == 0) {
        return;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (m_lFirstDateTime == 0) {
        m_lFirstDateTime = [userDefaults integerForKey:@"first_date_time"];
    }
    
    NSDate *now = [NSDate date];
    NSTimeInterval timeStampNow = [now timeIntervalSince1970];
    long daysFromStart = ((long)timeStampNow - m_lFirstDateTime) / (3600 * 24);
    NSString *strKey = [NSString stringWithFormat:@"%d_%@", (int)daysFromStart, strWiFiID];
    
    if (![userDefaults boolForKey:strKey]) {
        [userDefaults setBool:true forKey:strKey];
        [userDefaults synchronize];
    }
    
}


- (NSString*) saveHistory {
    
    NSDateFormatter *formatter,*TimeFormatter;
    NSString        *dateString;
    NSString        *timeString;
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    
    TimeFormatter = [[NSDateFormatter alloc] init];
    [TimeFormatter setDateFormat:@"HH:mm:ss"];
    
    dateString = [formatter stringFromDate:[NSDate date]];
    timeString = [TimeFormatter stringFromDate:[NSDate date]];
    
    NSString* strFilePath = [EngineMgr getHistoryWavePath:dateString time:timeString];
    
    [[EngineMgr sharedInstance] saveDetectedScream:strFilePath];
    
    return strFilePath;
}

- (void) saveHistoryOnParse:(NSString*)p_strFilePath {
    
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:p_strFilePath];
    PFFile *file = [PFFile fileWithName:@"scream_new.wav" data:data contentType:@"audio/x-wav"];
    [file save];
    
    PFUser *user = [PFUser currentUser];
    PFObject *detection = [PFObject objectWithClassName:@"detection_history"];
    detection[@"scream_file"] = file;
    detection[@"userObjectId"] = user.objectId;
    detection[@"userEmail"] = user.email;
    detection[@"device_type"] = @"iOS";
    
    if (user[@"phone"] != nil) {
        detection[@"phone"] = user[@"phone"];
    }

    if (user[@"postcode"] != nil) {
        detection[@"postcode"] = user[@"postcode"];
    }
    
    NSString *strFullName = [NSString stringWithFormat:@"%@ %@", user[@"first_name"], user[@"last_name"]];
    detection[@"fullname"] = strFullName;
    
    double dLatitude = 0;
    double dLongitude = 0;
    CLLocation* location = [[EMGLocationManager sharedInstance] m_location_gps];
    if (location != nil) {
        dLatitude = location.coordinate.latitude;
        dLongitude = location.coordinate.longitude;
    }
    NSString *strLocation = [NSString stringWithFormat:@"(%.4f, %.4f)", dLatitude, dLongitude];
    detection[@"location"] = strLocation;
    [detection save];
    
    NSString *strAddress = nil;
    // Set Address with WiFI
    NSString* strWiFiSSID = [EngineMgr currentWifiSSID];
    if (strWiFiSSID != nil) {
        int idx = [[EngineMgr sharedInstance] getWiFiItemIdx:strWiFiSSID];
        if (idx >= 0) {
            strAddress = [[EngineMgr sharedInstance] getWiFiAddressOfIndex:idx];
        }
    }
    
    // Set Address of GPS when there is no WIFI
    if (strAddress != nil) {
        detection[@"address"] = strAddress;
        [detection save];
    } else {
        if (location != nil) {
            [[EMGLocationManager sharedInstance] requestAddressWithLocation:location callback:^(NSString *szAddress) {
                if (szAddress != nil && [szAddress length] > 0) {
                    detection[@"address"] = szAddress;
                    [detection save];
                }
            }];
        } else {
        }
    }

}

#pragma mark - Glowing Effect
-(void)makeViewSmall {
    
    CGRect rect = m_imgDetectingStatus1.frame;
    rect.size.width -= 6;
    rect.size.height -= 6;
    rect.origin.x += 3;
    rect.origin.y += 3;
    m_imgDetectingStatus1.frame = rect;
    
    if (rect.size.width < m_imgDetectingStatus.frame.size.width) {
        [m_imgDetectingStatus1 setHidden:YES];
        rect.origin.x -= (260 - rect.size.width) / 2;
        rect.origin.y -= (260 - rect.size.height) / 2;
        rect.size.width = 260;
        rect.size.height = 260;
        m_imgDetectingStatus1.frame = rect;
        [self makeViewShine:m_imgDetectingStatus];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            [self makeViewSmall];
        });
    }
}

-(void)makeViewShine:(UIView*) view {
    view.layer.shadowColor = [UIColor whiteColor].CGColor;
    view.layer.shadowRadius = 10.0f;
    view.layer.shadowOpacity = 1.0f;
    view.layer.shadowOffset = CGSizeZero;
    
    m_nShineRequestCnt++;
    
    [UIView animateWithDuration:0.7f delay:0 options:(UIViewAnimationOptionAutoreverse | UIViewAnimationCurveEaseInOut | UIViewAnimationOptionRepeat | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        
        [UIView setAnimationRepeatCount:HUGE_VAL];
        
        view.transform = CGAffineTransformMakeScale(1.05f, 1.05f);
        
    } completion:^(BOOL finished) {
        m_nShineRequestCnt--;
        
        view.layer.shadowRadius = 0.0f;
        view.transform = CGAffineTransformMakeScale(1.0f, 1.0f);

        if (m_nShineRequestCnt == 0 && [[EngineMgr sharedInstance] isDetecting] && (![[EngineMgr sharedInstance] isBackground])) {
            [self makeViewShine:view];
        }
    }];
}


-(void) stopViewShine:(UIView*) view {
    view.layer.shadowColor = [UIColor yellowColor].CGColor;
    view.layer.shadowRadius = 0.0f;
    view.layer.shadowOpacity = 0.0f;
    view.layer.shadowOffset = CGSizeZero;
    [view.layer removeAllAnimations];
}

- (IBAction)unwindToHome:(UIStoryboardSegue *)unwindSegue
{
}

@end
