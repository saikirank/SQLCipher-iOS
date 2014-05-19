//
//  DTHSQLCipherUtils.m
//  SQLCipherTest
//
//  Created by Alban Diquet on 5/18/14.
//  Copyright (c) 2014 Alban Diquet. All rights reserved.
//

#import <sqlite3.h>
#import "DTHSQLCipherUtils.h"


// SQL statements
static const char testDbSQL[] = "SELECT count(*) FROM sqlite_master;";
static const char createTableSQL[] = "CREATE TABLE test (testcolumn TEXT)";
static const char insertTableSQL[] = "INSERT INTO test (testcolumn) VALUES ('testest123')";
static const char selectTableSQL[] = "SELECT * FROM test";


// This is just an example; do not hardcode the encryption key in the code!
static const char encryptionKey[] = "somesecretkey";


@implementation DTHSQLCipherUtils


+ (void)createDatabaseAtPath:(const char *)dbPath shouldEncrypt:(BOOL)shouldEncrypt {
    sqlite3 *dbConn = NULL;
    
    
    // Create the DB
    if (sqlite3_open_v2(dbPath, &dbConn, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) == SQLITE_OK) {

        // Set the encryption key
        if (shouldEncrypt) {
            sqlite3_key(dbConn, encryptionKey, strlen(encryptionKey));
        }
        
        // Test SQL request to ensure that the DB was properly initialized
        if (sqlite3_exec(dbConn, testDbSQL, NULL, NULL, NULL) == SQLITE_OK) {
            // Database has been initialized
        } else {
            // Error?
            NSLog(@"DB initialization error");
        }
        
        sqlite3_close(dbConn);
    }
    else {
        NSLog(@"Could not create the database!");
    }
}

+ (void)populateDatabase:(const char *)dbPath isEncrypted:(BOOL)isEncrypted {
    sqlite3 *dbConn = NULL;
    
    // Open the DB
    if (sqlite3_open_v2(dbPath, &dbConn, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK) {
        
        // Set the encryption key
        if (isEncrypted) {
            sqlite3_key(dbConn, encryptionKey, strlen(encryptionKey));
        }
        
        // Test SQL request to ensure that the DB was properly initialized
        if (sqlite3_exec(dbConn, testDbSQL, NULL, NULL, NULL) == SQLITE_OK) {
            // Database has been initialized
    		// Create the test table
    		if (sqlite3_exec(dbConn, createTableSQL, NULL, NULL, NULL) != SQLITE_OK) {
                NSLog(@"DB initialization error");
            }
            // Insert data in it
    		if (sqlite3_exec(dbConn, insertTableSQL, NULL, NULL, NULL) != SQLITE_OK) {
                NSLog(@"DB initialization error");
            }
            
        } else {
            // Error? Wrong password ?
            NSLog(@"Could not open the database!");
        }
        
        sqlite3_close(dbConn);
    }
    else {
        NSLog(@"Could not create the database!");
    }
}


+ (NSString*)fetchContentFromDatabase:(const char *)dbPath isEncrypted:(BOOL)isEncrypted {
    sqlite3 *dbConn = NULL;
    NSString *queryResult = nil;
    
    // Open the DB
    if (sqlite3_open_v2(dbPath, &dbConn, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK) {
        
        // Set the encryption key
        if (isEncrypted) {
            sqlite3_key(dbConn, encryptionKey, strlen(encryptionKey));
        }
        
        // Test SQL request to ensure that the DB was properly initialized
        if (sqlite3_exec(dbConn, testDbSQL, NULL, NULL, NULL) == SQLITE_OK) {
            // Database has been initialized
            sqlite3_stmt    *statement;
            
            if (sqlite3_prepare_v2(dbConn, selectTableSQL, -1, &statement, NULL) == SQLITE_OK) {
                if (sqlite3_step(statement) == SQLITE_ROW) {
                    queryResult = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 0)];
                } else {
                    // Not found
                }
                sqlite3_finalize(statement);
            }
        } else {
            // Wrong password?
            NSLog(@"Could not open the database!");
        }
        
        sqlite3_close(dbConn);
    }
    else {
        NSLog(@"Could not open the database!");
    }
    return queryResult;
}



+ (void)convertDatabaseAtPath:(const char *)dbPath toEncryptedDatabaseAtPath:(const char *)encryptedDbPath {
    /* Following the instructions at http://sqlcipher.net/sqlcipher-api/#sqlcipher_export
     sqlite> ATTACH DATABASE 'encrypted.db' AS encrypted KEY 'testkey';
     sqlite> SELECT sqlcipher_export('encrypted');
     sqlite> DETACH DATABASE encrypted;
     */
    
    // First create an empty encrypted DB
    [self createDatabaseAtPath:encryptedDbPath shouldEncrypt:YES];
    
    // Then export the content of the plaintext DB we want to convert to the newly created encrypted DB
    // Open the plaintext DB
    sqlite3 *dbConn = NULL;
    if (sqlite3_open_v2(dbPath, &dbConn, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK) {
        
        // Test SQL request to ensure that the DB was properly opened
        if (sqlite3_exec(dbConn, testDbSQL, NULL, NULL, NULL) == SQLITE_OK) {
            
            // Attach the encrypted DB
            NSString *ATTACH_SQL = @"ATTACH DATABASE '%s' AS encrypted KEY %s";
            const char *attachSqlStm =  [[NSString stringWithFormat:ATTACH_SQL, encryptedDbPath, encryptionKey] UTF8String];
            if (sqlite3_exec(dbConn, attachSqlStm, NULL, NULL, NULL) != SQLITE_OK) {
                NSLog(@"Attach failed!");
                sqlite3_close(dbConn);
                return;
            }
            
            // Export the plaintext DB's content to the encrypted DB
            if (sqlite3_exec(dbConn, "SELECT sqlcipher_export('encrypted');", NULL, NULL, NULL) != SQLITE_OK) {
                NSLog(@"sqlcipher_export() failed!");
                sqlite3_close(dbConn);
                return;
            }
            
            // Detach the encrypted DB
            if (sqlite3_exec(dbConn, "DETACH DATABASE encrypted;", NULL, NULL, NULL) != SQLITE_OK) {
                NSLog(@"Detach failed!");
                sqlite3_close(dbConn);
                return;
            }
            
        } else {
            // Error
            NSLog(@"DB initialization error");
        }
        
        sqlite3_close(dbConn);
    }
    else {
        NSLog(@"Could not create the database!");
    }
    
}


@end
