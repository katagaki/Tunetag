#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A thin wrapper around TagLib::FileRef. Each instance owns its own file handle,
/// so instances must not be shared across concurrent tasks.
@interface TagLibFile : NSObject

- (nullable instancetype)initWithPath:(NSString *)path;
- (instancetype)init NS_UNAVAILABLE;

/// Every property in the file, keyed by TagLib's standard property names (TITLE, ARTIST, ...).
@property (nonatomic, readonly) NSDictionary<NSString *, NSArray<NSString *> *> *properties;

/// The front cover, or the first picture if no picture is marked as the front cover.
@property (nonatomic, readonly, nullable) NSData *frontCover;

/// Whether the format stores track and disc totals in their own fields (TRACKTOTAL, DISCTOTAL)
/// instead of as "number/total".
@property (nonatomic, readonly) BOOL usesSeparateTotals;

/// Property keys that the last save could not write to this format.
@property (nonatomic, readonly) NSArray<NSString *> *unsupportedProperties;

/// Sets the values for a property. Passing nil or an empty array removes the property.
- (void)setValues:(nullable NSArray<NSString *> *)values forProperty:(NSString *)key;

/// Replaces the front cover. Passing nil removes it. Other pictures are kept.
- (void)setFrontCover:(nullable NSData *)data;

- (BOOL)save;

/// Removes every tag from the file and writes the change to disk.
- (BOOL)removeAllTags;

+ (NSArray<NSString *> *)supportedExtensions;

@end

NS_ASSUME_NONNULL_END
