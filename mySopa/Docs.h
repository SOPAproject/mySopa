//
//  Docs.h
//  mySopa
//
//  Created by 蘆原 郁 on 2014/03/28.
//  Copyright (c) 2014年 jp.go.aist.staff. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface Docs : NSManagedObject

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *path;
@property (nonatomic, retain) NSDate * timeStamp;

@end
