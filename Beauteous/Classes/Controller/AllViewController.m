//
//  AllViewController.m
//  Beauteous
//
//  Created by Kenichi Saito on 7/29/15.
//  Copyright (c) 2015 Kenichi Saito. All rights reserved.
//

#import "AllViewController.h"
#import "PreviewViewController.h"
#import "BOUtility.h"
#import "BOConst.h"
#import "Note.h"
#import "NoteManager.h"
#import "AllTableViewCell.h"
#import "PhotoAllTableViewCell.h"
#import "DetailViewController.h"

#import "FontAwesomeKit/FontAwesomeKit.h"
#import "MCSwipeTableViewCell.h"
#import "AMWaveTransition.h"


@interface AllViewController () <UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation AllViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"All";
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 8, 0, 0);
    self.tableView.layoutMargins = UIEdgeInsetsMake(0, 8, 0, 0);
    self.tableView.separatorColor = [UIColor lightGrayColor];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.searchBar.backgroundImage = [UIImage new];
    self.searchBar.tintColor = [UIColor blackColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NoteManager sharedManager] fetchAllNotes];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setDelegate:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [NoteManager sharedManager].notes.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Note *note = [NoteManager sharedManager].notes[indexPath.row];
    
    if ([note.photoUrl isEqualToString:@""]) {
        
        AllTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (cell == nil) {
            cell = [[AllTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        }
        [self configureCell:cell andIndexPath:indexPath];
        
        return cell;
    }

    PhotoAllTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PhotoCell"];
    if (cell == nil) {
        cell = [[PhotoAllTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PhotoCell"];
    }
    [self configurePhotoCell:cell andIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(AllTableViewCell*)cell andIndexPath:(NSIndexPath *)indexPath
{
    Note *note = [NoteManager sharedManager].notes[indexPath.row];
    [cell setDate:note];
    
    __weak AllViewController *weakSelf = self;
    
    UILabel *starLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width / 5, cell.bounds.size.height)];
    
    if (note.starred) {
        starLabel.text = @"Un Star";
    } else {
        starLabel.text = @"Star";
    }
    
    starLabel.font = [BOUtility fontTypeMediumWithSize:17];
    starLabel.textAlignment = NSTextAlignmentCenter;
    starLabel.textColor = [BOUtility yellowColor];
    
    [cell setSwipeGestureWithView:starLabel
                            color:[UIColor whiteColor]
                             mode:MCSwipeTableViewCellModeSwitch
                            state:MCSwipeTableViewCellState1
                  completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
                      // Update Method
                      
                      [[NoteManager sharedManager] starringNote:note];
                      [weakSelf.tableView reloadData];
                      
    }];
    
    UILabel *deleteLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width / 5, cell.bounds.size.height)];
    deleteLabel.font = [BOUtility fontTypeMediumWithSize:17];
    deleteLabel.text = @"Delete";
    deleteLabel.textAlignment = NSTextAlignmentCenter;
    deleteLabel.textColor = [BOUtility pinkColor];

    [cell setSwipeGestureWithView:deleteLabel
                            color:[UIColor whiteColor]
                             mode:MCSwipeTableViewCellModeSwitch
                            state:MCSwipeTableViewCellState3
                  completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
                      
                      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete?" message:@"Are you sure want to delete the cell?" preferredStyle:UIAlertControllerStyleAlert];
                      UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                          [alert dismissViewControllerAnimated:YES completion:nil];
                      }];
                      UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
                          [[NoteManager sharedManager] deleteObject:note];
                          [weakSelf.tableView reloadData];
                      }];
                      
                      [alert addAction:noAction];
                      [alert addAction:yesAction];
                      
                      [weakSelf presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)configurePhotoCell:(PhotoAllTableViewCell*)cell andIndexPath:(NSIndexPath *)indexPath
{
    Note *note = [NoteManager sharedManager].notes[indexPath.row];
    [cell setDate:note];
    
    __weak AllViewController *weakSelf = self;
    
    UILabel *starLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width / 5, cell.bounds.size.height)];
    
    if (note.starred) {
        starLabel.text = @"Un Star";
    } else {
        starLabel.text = @"Star";
    }
    
    starLabel.font = [BOUtility fontTypeMediumWithSize:17];
    starLabel.textAlignment = NSTextAlignmentCenter;
    starLabel.textColor = [BOUtility yellowColor];
    
    [cell setSwipeGestureWithView:starLabel
                            color:[UIColor whiteColor]
                             mode:MCSwipeTableViewCellModeSwitch
                            state:MCSwipeTableViewCellState1
                  completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
                      // Update Method
                      
                      [[NoteManager sharedManager] starringNote:note];
                      [weakSelf.tableView reloadData];
                      
                  }];
    
    UILabel *deleteLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width / 5, cell.bounds.size.height)];
    deleteLabel.font = [BOUtility fontTypeMediumWithSize:17];
    deleteLabel.text = @"Delete";
    deleteLabel.textAlignment = NSTextAlignmentCenter;
    deleteLabel.textColor = [BOUtility pinkColor];
    
    [cell setSwipeGestureWithView:deleteLabel
                            color:[UIColor whiteColor]
                             mode:MCSwipeTableViewCellModeSwitch
                            state:MCSwipeTableViewCellState3
                  completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
                      
                      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete?" message:@"Are you sure want to delete the cell?" preferredStyle:UIAlertControllerStyleAlert];
                      UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                          [alert dismissViewControllerAnimated:YES completion:nil];
                      }];
                      UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
                          [[NoteManager sharedManager] deleteObject:note];
                          [weakSelf.tableView reloadData];
                      }];
                      
                      [alert addAction:noAction];
                      [alert addAction:yesAction];
                      
                      [weakSelf presentViewController:alert animated:YES completion:nil];
                  }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Note *note = [NoteManager sharedManager].notes[indexPath.row];
    
    NSLog(@"%@", note);
        
    DetailViewController *detailVC = [[BOUtility storyboard] instantiateViewControllerWithIdentifier:@"Detail"];
    detailVC.note = note;
    self.navigationItem.backBarButtonItem = [BOUtility blankBarButton];
    [self.navigationController pushViewController:detailVC animated:YES];
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController*)fromVC
                                                 toViewController:(UIViewController*)toVC
{
    if (operation != UINavigationControllerOperationNone) {
        return [AMWaveTransition transitionWithOperation:operation];
    }
    return nil;
}

- (void)dealloc
{
    [self.navigationController setDelegate:nil];
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
