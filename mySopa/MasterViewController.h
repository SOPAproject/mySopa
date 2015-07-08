//
//  MasterViewController.h
//  mySopa
//
//  Created by 蘆原 郁 on 2014/03/28.
//  Copyright (c) 2014年 jp.go.aist.staff. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

#import <CoreData/CoreData.h>

@interface MasterViewController : UIViewController <UITableViewDelegate, NSFetchedResultsControllerDelegate, UITableViewDataSource>{
    UITableView *_tableView;
}

@property (strong, nonatomic) IBOutlet UITextField *mySearch;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) DetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) IBOutlet UITextView *myTextView;

-(NSInteger)supportedInterfaceOrientations; // Must return Orientation Mask

@end
