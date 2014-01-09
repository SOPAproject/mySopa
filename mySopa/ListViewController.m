//
//  ListViewController.m
//  mySopa
//
//  Created by Kaoru Ashihara on 13/10/03.
//  Copyright (c) 2013, AIST. All rights reserved.
//

#import "ListViewController.h"

@interface ListViewController ()
@end

@implementation ListViewController{
    CGRect textRect;
    CGRect tableRect;
}

@synthesize mySearch = _mySearch;
@synthesize tableView = _tableView;
@synthesize objects = _objects;
@synthesize myTextView = _myTextView;
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
    
    _mySearch.delegate = self;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    filePath = [directory stringByAppendingPathComponent:@"data.plist"];
    
    _objects = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
    sItemNum = _objects.count;

    if(sItemNum != 0) {
        str = [_objects objectAtIndex:0];
    }
    else {
        _objects = [NSMutableArray arrayWithObjects:@"http://staff.aist.go.jp/ashihara-k/resource/sopa_version2_22k.sopa",
                     @"http://staff.aist.go.jp/ashihara-k/resource/v2demo22k.sopa",nil];
        str = @"http://staff.aist.go.jp/ashihara-k/resource/sopa_version2_22k.sopa";
    }
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.ViewController = (ViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    _mySearch.text = str;
    tableRect = _tableView.frame;
    
    _myTextView.editable = NO;
    _myTextView.dataDetectorTypes = UIDataDetectorTypeLink;
    _myTextView.textColor = [UIColor darkTextColor];
    _myTextView.text = @"-mySopa- Copyright (c) 2013, AIST\nhttp://staff.aist.go.jp/ashihara-k/mySopa.html";
}

-(void)viewDidUnload{
    if(_objects){
        BOOL successful = [_objects writeToFile:filePath atomically:NO];
        if(!successful){
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle : @"Data not saved"
                                      message:@"Failed to save data!"
                                      delegate : nil cancelButtonTitle : @"OK"
                                      otherButtonTitles : nil];
            [alertView show];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    str = _mySearch.text;
    
    [self.mySearch resignFirstResponder];
    
    for(sCount = 0;sCount < sNum;sCount ++){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sCount inSection:0];
        NSString *strFind = [_objects[indexPath.row] description];
        
        if([strFind isEqualToString:str]){
            sIndex = sCount;
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
    if(!successful){
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle : @"Data not savede"
                                  message:@"Failed to save data!"
                                  delegate : nil cancelButtonTitle : @"OK"
                                  otherButtonTitles : nil];
        [alertView show];
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

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
    [self.mySearch resignFirstResponder];
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
    [self.mySearch resignFirstResponder];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if(_objects.count <= 1){
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle : @"Not editable"
                                      message:@"You cannot delete the last item!"
                                      delegate : nil cancelButtonTitle : @"OK"
                                      otherButtonTitles : nil];
            [alertView show];
        }
        else{
            // Delete the row from the data source
            [_objects removeObjectAtIndex:indexPath.row]; // Delete item
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    BOOL successful = [_objects writeToFile:filePath atomically:NO];
    if(!successful){
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle : @"Data not savede"
                                  message:@"Failed to save data!"
                                  delegate : nil cancelButtonTitle : @"OK"
                                  otherButtonTitles : nil];
        [alertView show];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];
    
    [self performSegueWithIdentifier:@"showDetail" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *toPath = [NSIndexPath indexPathForRow:0 inSection:0];
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSIndexPath *fromPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
    
    if([[segue identifier] isEqualToString:@"showDetail"]) {
        NSDate *object = _objects[indexPath.row];
        ViewController *viewCon = segue.destinationViewController;
        
//        [viewCon performSelector:@selector(setDetailItem:)withObject:object afterDelay:0.1];
        [viewCon setDetailItem:object];
    }
    
    [self.tableView moveRowAtIndexPath:fromPath toIndexPath:toPath];
    
    id item = [_objects objectAtIndex:fromPath.row];
    [_objects removeObject:item];
    [_objects insertObject:item atIndex:toPath.row];
    _mySearch.text = [_objects[toPath.row] description];
    
    BOOL successful = [_objects writeToFile:filePath atomically:NO];
    if(!successful){
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle : @"Data not saved"
                                  message:@"Failed to save data!"
                                  delegate : nil cancelButtonTitle : @"OK"
                                  otherButtonTitles : nil];
        [alertView show];
    }
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {

}

@end
