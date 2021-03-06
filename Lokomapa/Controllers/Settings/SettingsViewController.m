//
//  SettingsViewController.m
//  Lokomapa
//
//  Created by ldomaradzki on 13.11.2013.
//  Copyright (c) 2013 ldomaradzki. All rights reserved.
//

#import "SettingsViewController.h"
#import "FAKFontAwesome.h"

#define ICON_SIZE 17


@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.toolbarTitle.text = NSLocalizedString(@"Settings", nil);
    self.toolbarCloseButton.title = NSLocalizedString(@"Close", nil);

    fontAwesomes = @[@[[FAKFontAwesome mapMarkerIconWithSize:ICON_SIZE], [FAKFontAwesome bellOIconWithSize:ICON_SIZE]], @[[FAKFontAwesome linkIconWithSize:ICON_SIZE], [FAKFontAwesome questionIconWithSize:ICON_SIZE], [FAKFontAwesome githubIconWithSize:ICON_SIZE]]];
    
    if (IS_IPHONE) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    }
}

-(UIImage *)fontAwesomeImageWithIcon:(FAKFontAwesome*)fontAwesome {
    [fontAwesome setAttributes:@{NSForegroundColorAttributeName: RGBA(91, 140, 169, 1)}];
    return [fontAwesome imageWithSize:CGSizeMake(30, 30)];
}

-(void)cellSwitchAction:(UISwitch*)cellSwitch {
    [[NSUserDefaults standardUserDefaults] setBool:cellSwitch.on forKey:@"showingPinTitle"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UITableView

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return 2;
    if (section == 1)
        return 3;
    
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CELL"];
 
    if (indexPath.section == 0) {
        cell.textLabel.text =
        @[NSLocalizedString(@"Showing pin title", nil), [NSString stringWithFormat:NSLocalizedString(@"Clear all notifications (%d)", nil), [[UIApplication sharedApplication] scheduledLocalNotifications].count]][indexPath.row];
        
        if (indexPath.row == 0) {
            UISwitch *cellSwitch = [[UISwitch alloc] init];
            [cellSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"showingPinTitle"] animated:NO];
            cellSwitch.onTintColor = RGBA(91, 140, 169, 1);
            [cellSwitch addTarget:self action:@selector(cellSwitchAction:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = cellSwitch;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    
    if (indexPath.section == 1) {
        cell.textLabel.text = @[@"SITkol - rozklad.sitkol.pl", NSLocalizedString(@"Have a question?", nil), NSLocalizedString(@"About", nil)][indexPath.row];
        cell.detailTextLabel.text = @[NSLocalizedString(@"Data provider", nil), NSLocalizedString(@"Send me an e-mail!", nil), NSLocalizedString(@"Know more about this app", nil)][indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.indentationWidth = 20;
    cell.indentationLevel = 1;
    
    UIImageView *fontAwesomeImageView = [[UIImageView alloc] init];
    fontAwesomeImageView.image = [self fontAwesomeImageWithIcon:fontAwesomes[indexPath.section][indexPath.row]];
    fontAwesomeImageView.contentMode = UIViewContentModeCenter;
    fontAwesomeImageView.frame = CGRectMake(0, 0, 35, 44);
    
    [cell.contentView addSubview:fontAwesomeImageView];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0 && indexPath.row == 1) {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        [self.tableView reloadData];
    }
    
    if (indexPath.section == 1) {
        if (indexPath.row == 0) { // SITkol
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://rozklad.sitkol.pl/"]];
        }
        
        if (indexPath.row == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:lukasz.domaradzki@gmail.com"]];
        }
        
        if (indexPath.row == 2) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/ldomaradzki/Lokomapa"]];
        }
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @[NSLocalizedString(@"General settings", nil), NSLocalizedString(@"Application info", nil)][section];
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 1) {
        UIImageView *footer =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SettingsFooter"]];
        [footer setContentMode:UIViewContentModeScaleAspectFit];
        return footer;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1) {
        if (IS_IPHONE) {
            return 150;
        } else {
            return 250;
        }
    }
    
    return 0;
}

- (IBAction)dismissModalWindow:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
