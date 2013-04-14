//
//  ListViewController.m
//  mySopa
//
//  Created by Kaoru Ashihara on 13/04/03.
//  Copyright (c) 2013, AIST. All rights reserved.
//

#import "ListViewController.h"

@interface ListViewController (){

    UIActivityIndicatorView *mySpinner;
}

@end

@implementation ListViewController

@synthesize myText = _myText;
@synthesize tableView = _tableView;
@synthesize myLabel = _myLabel;
@synthesize objects = _objects;
@synthesize filePath;

- (id)initView
{
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    SInt16 sItemNum;
    [super viewDidLoad];

    _myText.delegate = self;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    filePath = [directory stringByAppendingPathComponent:@"data.plist"];
    
    _objects = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
    sItemNum = _objects.count;
    if (sItemNum != 0) {
//        NSLog(@"%d items found",sItemNum);
        str = [_objects objectAtIndex:0];
    }
    else {
        NSLog(@"There is no data");
        str = @"http://staff.aist.go.jp/ashihara-k/resource/sopa22k.sopa";
    }
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.ViewController = (ViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    _myText.text = str;
    _myLabel.textColor = [UIColor lightTextColor];
    _myLabel.numberOfLines = 2;
    _myLabel.text = @"mySopa\nCopyright (c) 2013, AIST";

    mySpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [mySpinner setColor:[UIColor purpleColor]];

}

-(void)viewDidUnload{
    if(_objects){
        BOOL successful = [_objects writeToFile:filePath atomically:NO];
        if (successful) {
            NSLog(@"Data saved successfully");
        }
        else
            NSLog(@"Failed to save data");
    }
    [mySpinner removeFromSuperview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
}

- (void)insertNewObject:(id)sender
{
    SInt16 sNum,sIndex = 0;
    SInt16 sCount = 0;
    BOOL isExist = NO;
    
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    sNum = _objects.count;
    str = _myText.text;
    
    [self.myText resignFirstResponder];

    for(sCount = 0;sCount < sNum;sCount ++){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sCount inSection:0];
        NSString *strFind = [_objects[indexPath.row] description];

        if([strFind isEqualToString:str]){
            sIndex = sCount;
//            NSLog(@"I found it");
            isExist = YES;
            sCount = sNum;
        }
    }
    if(isExist){
        NSIndexPath *toPath = [NSIndexPath indexPathForRow:0 inSection:0];
        NSIndexPath *fromPath = [NSIndexPath indexPathForRow:sIndex inSection:0];
        [self.tableView moveRowAtIndexPath:fromPath toIndexPath:toPath];
        id item = [_objects objectAtIndex:fromPath.row];
        [_objects removeObject:item];
        [_objects insertObject:item atIndex:toPath.row];
    }
    else{
        [_objects insertObject:str atIndex:0];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }

    BOOL successful = [_objects writeToFile:filePath atomically:NO];
    if (successful) {
        NSLog(@"Data saved successfully");
    }
    else
        NSLog(@"Failed to save data");

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *strTitle;

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myCell" forIndexPath:indexPath];

    NSDate *object = _objects[indexPath.row];
    strTitle = [[[object description] componentsSeparatedByString:@"/"] lastObject];

    cell.textLabel.text = strTitle;
    [self.myText resignFirstResponder];
    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    
    str = textField.text;
    
    return YES;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.myText resignFirstResponder];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [_objects removeObjectAtIndex:indexPath.row]; // Delete item
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
    BOOL successful = [_objects writeToFile:filePath atomically:NO];
    if (successful) {
        NSLog(@"Data saved successfully");
    }
    else
        NSLog(@"Failed to save data");
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSLog(@"Data move");
    if(fromIndexPath.section == toIndexPath.section) {
        if(_objects && toIndexPath.row < [_objects count]) {
            id item = [_objects objectAtIndex:fromIndexPath.row]; 
            [_objects removeObject:item];
            [_objects insertObject:item atIndex:toIndexPath.row];
        }
    }
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:mySpinner];
    [mySpinner startAnimating];
    _myLabel.textColor = [UIColor yellowColor];
    _myLabel.text = @"Loading database\nPlease wait";
    
    [self performSelector:@selector(performBeforeSegue)withObject:nil afterDelay:0.1];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *toPath = [NSIndexPath indexPathForRow:0 inSection:0];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSIndexPath *fromPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
    
    if([[segue identifier] isEqualToString:@"showDetail"]) {
        NSDate *object = _objects[indexPath.row];
        ViewController *viewCon = segue.destinationViewController;
        
        [viewCon setDetailItem:object];
    }
    
    [self.tableView moveRowAtIndexPath:fromPath toIndexPath:toPath];
    
    id item = [_objects objectAtIndex:fromPath.row];
    [_objects removeObject:item];
    [_objects insertObject:item atIndex:toPath.row];
    _myText.text = [_objects[toPath.row] description];

    BOOL successful = [_objects writeToFile:filePath atomically:NO];
    if (successful) {
        NSLog(@"Data saved successfully");
    }
    else
        NSLog(@"Failed to save data");
    
    _myLabel.textColor = [UIColor lightTextColor];
    _myLabel.text = @"mySopa\nCopyright 2013, AIST";
    [mySpinner stopAnimating];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

}

-(void)performBeforeSegue{
    [self performSegueWithIdentifier:@"showDetail" sender:self];
}

@end