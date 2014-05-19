//
//  DTHSQLCipherUtils.h
//  SQLCipherTest
//
//  Created by Alban Diquet on 5/18/14.
//  Copyright (c) 2014 Alban Diquet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTHSQLCipherUtils : NSObject

// Create a DB which will be encrypted using SQLcipher if shouldEncrypt is true.
+ (void)createDatabaseAtPath:(const char *)dbPath shouldEncrypt:(BOOL)shouldEncrypt;

// Add some test data to an existing DB
+ (void)populateDatabase:(const char *)dbPath isEncrypted:(BOOL)isEncrypted;

// Fetch the test data from an existing DB
+ (NSString*)fetchContentFromDatabase:(const char *)dbPath isEncrypted:(BOOL)isEncrypted;

// Encrypt a pre-existing plaintext DB
+ (void)convertDatabaseAtPath:(const char *)dbPath toEncryptedDatabaseAtPath:(const char *)encryptedDbPath;

@end
