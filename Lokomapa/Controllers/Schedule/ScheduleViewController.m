//
//  ScheduleViewController.m
//  Lokomapa
//
//  Created by ldomaradzki on 29.09.2013.
//  Copyright (c) 2013 ldomaradzki. All rights reserved.
//

#import "ScheduleViewController.h"
#import "Schedule.h"
#import "Station.h"
#import "TrainScheduleViewController.h"
#import <Social/Social.h>
#import "FAKFontAwesome.h"

@implementation ScheduleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicatorView.hidesWhenStopped = YES;
    [indicatorView startAnimating];
    indicatorView.center = self.view.center;
    [self.view addSubview:indicatorView];
    
    self.separatorLineView.hidden = YES;
    self.pickerView.hidden = YES;
    
    [self updateScheduleDataWithRefreshControl:indicatorView];
    
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    [self addRefreshBarButton];
}

-(void)addRefreshBarButton {
    FAKFontAwesome *refreshIcon = [FAKFontAwesome refreshIconWithSize:20];
    [refreshIcon addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
    UIImage *rightImage = [refreshIcon imageWithSize:CGSizeMake(20, 20)];
    refreshIcon.iconFontSize = 15;
    UIImage *rightLandscapeImage = [refreshIcon imageWithSize:CGSizeMake(15, 15)];
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithImage:rightImage
                       landscapeImagePhone:rightLandscapeImage
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(updateScheduleDataWithRefreshControl:)];
}

-(void)viewDidAppear:(BOOL)animated {
    self.title = self.station.name;
}

-(void)updateScheduleDataWithRefreshControl:(id)sender {
    
    
    [Schedule stationBetterSchedule:self.station.externalId withBlock:^(Schedule *schedule, NSError *error) {
        self.schedule = schedule;
        
        [self setStationNames];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (sender) {
                if ([sender isKindOfClass:[UIActivityIndicatorView class]]) {
                    [sender removeFromSuperview];
                }
            }
            
            self.separatorLineView.hidden = NO;
            self.pickerView.hidden = NO;
            
            self.filteredJourneys = [self.schedule.journeys mutableCopy];
            
            [self.tableView reloadData];
            [self.pickerView reloadAllComponents];
            [self.pickerView selectRow:0 inComponent:0 animated:YES];
        });
    }];
}

-(void)setStationNames {
    NSMutableArray *stationsStringArray = [NSMutableArray array];
    for (Journey *journey in self.schedule.journeys) {
        [stationsStringArray addObject:journey.destinationStation];
    }
    
    stationNames = [[[NSSet setWithArray:stationsStringArray] allObjects] mutableCopy];
    
    [stationNames sortUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
        int obj1count = 0;
        int obj2count = 1;
        
        for (NSString *station in stationsStringArray) {
            if ([station isEqualToString:obj1])
                obj1count++;
            
            if ([station isEqualToString:obj2])
                obj2count++;
        }
        
        if (obj1count > obj2count)
            return NSOrderedAscending;
        else if (obj1count < obj2count)
            return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
}

-(void)handleRefresh:(UIRefreshControl*)sender {
    [self updateScheduleDataWithRefreshControl:sender];
}

-(void)prepareForStation:(Station *)scheduleForStation {
    self.station = scheduleForStation;
    [self updateScheduleDataWithRefreshControl:nil];
}

#pragma mark - TableView

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredJourneys.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CELL"];

    Journey *cellJourney = self.filteredJourneys[indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", [cellJourney. arrivalTime getHourMinuteString], cellJourney.destinationStation];
    cell.detailTextLabel.text = cellJourney.train;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [UIColor clearColor];
    
    if ([cellJourney getDelayString].length > 0) {
        UILabel *delayLabel = [[UILabel alloc] initWithFrame:CGRectMake(180, 21, 100, 24)];
        delayLabel.font = [UIFont systemFontOfSize:12];
        delayLabel.textColor = [UIColor blackColor];
        delayLabel.textAlignment = NSTextAlignmentRight;
        delayLabel.text = [cellJourney getDelayString];
        
        [cell.contentView addSubview:delayLabel];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    currentJourney = self.filteredJourneys[indexPath.row];
    
    NSDate *currentDate = [NSDate date];
    
    if ([currentJourney.arrivalTime compare:currentDate] == NSOrderedAscending) {
        firstActionSheet = [[UIActionSheet alloc] initWithTitle:[self getInfoStringForJourney:currentJourney] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Check full schedule", nil), NSLocalizedString(@"Send or share", nil), nil];
    } else {
        firstActionSheet = [[UIActionSheet alloc] initWithTitle:[self getInfoStringForJourney:currentJourney] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Check full schedule", nil), NSLocalizedString(@"Send or share", nil), NSLocalizedString(@"Set notification", nil), nil];
    }
    
    [firstActionSheet showInView:self.view];
}

-(NSString*)getInfoStringForJourney:(Journey*)journey {
    NSString *pasteString =
    [NSString stringWithFormat:@"%@: %@ (-> %@) @ %@",
     self.station.name, journey.train, journey.destinationStation, [journey.arrivalTime getHourMinuteString]];
    if ([journey getDelayString].length > 0) {
        pasteString = [pasteString stringByAppendingFormat:@" (%@)", [journey getDelayString]];
    }
    return pasteString;
}

-(void)clipboardActionsForJourney:(Journey*)journey {
    [[UIPasteboard generalPasteboard] setString:[self getInfoStringForJourney:journey]];
    
    shareActionSheet = [[UIActionSheet alloc] initWithTitle:[self getInfoStringForJourney:journey] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Send SMS/iMessage", nil), NSLocalizedString(@"Send mail", nil), NSLocalizedString(@"Share of Facebook", nil), NSLocalizedString(@"Share on Twitter", nil), nil];
    [shareActionSheet showInView:self.view];
}

-(void)notificationActionForJourney:(Journey*)journey {
    notificationActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Set notification for this train before:", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"5 minutes", nil), NSLocalizedString(@"10 minutes", nil), NSLocalizedString(@"20 minutes", nil), NSLocalizedString(@"30 minutes", nil), NSLocalizedString(@"1 hour", nil), nil];
    [notificationActionSheet showInView:self.view];
}

#pragma mark - Actionsheet methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == firstActionSheet) {
        switch (buttonIndex) {
            case 0: {
                [self showFullScheduleScreen];
                break;
            }
                
            case 1: {
                [self clipboardActionsForJourney:currentJourney];
                break;
            }
                
            case 2: {
                if ([currentJourney.arrivalTime compare:[NSDate date]] != NSOrderedAscending) {
                    [self notificationActionForJourney:currentJourney];
                }
                
                break;
            }
                
            default:
                break;
        }
    }
    
    if (actionSheet == shareActionSheet) {
        switch (buttonIndex) {
             case 0: {
                 [self sendSMSMessage:[self getInfoStringForJourney:currentJourney]];
                 break;
             }
                
            case 1: {
                [self sendMailMessage:[self getInfoStringForJourney:currentJourney]];
                break;
            }

             case 2: {
                 [self sendSocialMessage:[self getInfoStringForJourney:currentJourney] forType:SLServiceTypeFacebook];
                 break;
             }

             case 3: {
                 [self sendSocialMessage:[self getInfoStringForJourney:currentJourney] forType:SLServiceTypeTwitter];
                 break;
             }
                 
             default:
                 break;
         }
    }
    
    if (actionSheet == notificationActionSheet) {
        switch (buttonIndex) {
            case 0: {
                [self setNotificationTime:@5 forJourney:currentJourney];
                break;
            }
                
            case 1: {
                [self setNotificationTime:@10 forJourney:currentJourney];
                break;
            }
                
            case 2: {
                [self setNotificationTime:@20 forJourney:currentJourney];
                break;
            }
                
            case 3: {
                [self setNotificationTime:@30 forJourney:currentJourney];
                break;
            }
                
            case 4: {
                [self setNotificationTime:@60 forJourney:currentJourney];
                break;
            }
                
            default:
                break;
        }
    }
}

-(void)showFullScheduleScreen {
    [self performSegueWithIdentifier:@"schedule2web" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    TrainScheduleViewController *trainSchedule = (TrainScheduleViewController*)segue.destinationViewController;
    
    trainSchedule.trainId = currentJourney.trainId;
}

#pragma mark - Local notification

-(void)setNotificationTime:(NSNumber*)time forJourney:(Journey*)journey {
    UILocalNotification *localNotification = [UILocalNotification new];

    localNotification.repeatInterval = 0;
    localNotification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"Scheduled train notification: %@", nil), [self getInfoStringForJourney:journey]];
    localNotification.fireDate = [journey.arrivalTime dateByAddingTimeInterval:-60.0f * time.floatValue];
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

#pragma mark - Social method

-(void)sendSocialMessage:(NSString*)message forType:(NSString*)type {
    if ([SLComposeViewController isAvailableForServiceType:type]) {
        SLComposeViewController *facebookComposeViewController = [SLComposeViewController composeViewControllerForServiceType:type];
        
        [facebookComposeViewController setInitialText:message];
        [self presentViewController:facebookComposeViewController animated:YES completion:nil];
    }
}


#pragma mark - Message method & delegate

-(void)sendSMSMessage:(NSString*)message {
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *messageComposeViewController = [[MFMessageComposeViewController alloc] init];
        messageComposeViewController.body = message;
        messageComposeViewController.messageComposeDelegate = self;
        
        [self presentViewController:messageComposeViewController animated:YES completion:nil];
    }
}

-(void)sendMailMessage:(NSString*)message {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *messageComposeViewController = [[MFMailComposeViewController alloc] init];
        [messageComposeViewController setMessageBody:message isHTML:NO];
        messageComposeViewController.mailComposeDelegate = self;
        
        [self presentViewController:messageComposeViewController animated:YES completion:nil];
    }
}

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIPickerview delegate & datasource

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (stationNames.count > 0)
        return stationNames.count + 1;
    return 0;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row == 0) {
        return NSLocalizedString(@"ALL", nil);
    } else {
        row--;
        int count = 0;
        for (Journey *journey in self.schedule.journeys) {
            if ([journey.destinationStation isEqualToString:stationNames[row]])
                count++;
        }
        
        return [NSString stringWithFormat:@"%@ (%d)", stationNames[row], count];
    }
    
    return nil;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row == 0) {
        self.filteredJourneys = [self.schedule.journeys mutableCopy];
    }
    else {
        row--;
        
        self.filteredJourneys = [NSMutableArray array];
        
        for (Journey *journey in self.schedule.journeys) {
            if ([journey.destinationStation isEqualToString:stationNames[row]]) {
                [self.filteredJourneys addObject:journey];
            }
        }
    }
    [self.tableView reloadData];
}

@end
