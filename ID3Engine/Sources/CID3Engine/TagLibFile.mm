#import "TagLibFile.h"

#include <memory>

#include <taglib/fileref.h>
#include <taglib/flacfile.h>
#include <taglib/id3v2framefactory.h>
#include <taglib/mp4file.h>
#include <taglib/mpegfile.h>
#include <taglib/oggfile.h>
#include <taglib/tpropertymap.h>

static const char *const kFrontCoverType = "Front Cover";

static bool IsFrontCover(const TagLib::VariantMap &picture) {
    return picture.value("pictureType").value<TagLib::String>() == kFrontCoverType;
}

static NSString *ToNSString(const TagLib::String &string) {
    return [NSString stringWithUTF8String:string.toCString(true)] ?: @"";
}

static TagLib::String ToTagLibString(NSString *string) {
    return TagLib::String(string.UTF8String, TagLib::String::UTF8);
}

static NSString *ImageMimeType(NSData *data) {
    const auto *bytes = static_cast<const unsigned char *>(data.bytes);
    if (data.length >= 8 && bytes[0] == 0x89 && bytes[1] == 'P' && bytes[2] == 'N' && bytes[3] == 'G') {
        return @"image/png";
    }
    if (data.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return @"image/jpeg";
    }
    if (data.length >= 6 && bytes[0] == 'G' && bytes[1] == 'I' && bytes[2] == 'F') {
        return @"image/gif";
    }
    if (data.length >= 2 && bytes[0] == 'B' && bytes[1] == 'M') {
        return @"image/bmp";
    }
    return @"image/jpeg";
}

@implementation TagLibFile {
    NSString *_path;
    std::unique_ptr<TagLib::FileRef> _fileRef;
    TagLib::PropertyMap _properties;
    NSArray<NSString *> *_unsupportedProperties;
}

+ (void)initialize {
    if (self == [TagLibFile class]) {
        // Files are saved as ID3v2.4, which supports UTF-8 text frames.
        TagLib::ID3v2::FrameFactory::instance()->setDefaultTextEncoding(TagLib::String::UTF8);
    }
}

- (nullable instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    _path = [path copy];
    _unsupportedProperties = @[];
    if (![self reopen]) {
        return nil;
    }
    return self;
}

/// Opens the file again. Closing the previous FileRef flushes TagLib's buffered writes to disk,
/// so other readers see the saved tags immediately.
- (BOOL)reopen {
    try {
        _fileRef.reset();
        _fileRef = std::make_unique<TagLib::FileRef>(_path.fileSystemRepresentation, false);
        if (_fileRef->isNull()) {
            return NO;
        }
        _properties = _fileRef->properties();
        return YES;
    } catch (...) {
        return NO;
    }
}

- (NSDictionary<NSString *, NSArray<NSString *> *> *)properties {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (const auto &[key, values] : _properties) {
        NSMutableArray *array = [NSMutableArray array];
        for (const auto &value : values) {
            [array addObject:ToNSString(value)];
        }
        result[ToNSString(key)] = array;
    }
    return result;
}

- (NSArray<NSString *> *)unsupportedProperties {
    return _unsupportedProperties;
}

- (BOOL)usesSeparateTotals {
    TagLib::File *file = _fileRef->file();
    return dynamic_cast<TagLib::FLAC::File *>(file) != nullptr ||
           dynamic_cast<TagLib::Ogg::File *>(file) != nullptr;
}

- (void)setValues:(nullable NSArray<NSString *> *)values forProperty:(NSString *)key {
    TagLib::String tagLibKey = ToTagLibString(key.uppercaseString);
    if (values.count == 0) {
        _properties.erase(tagLibKey);
        return;
    }
    TagLib::StringList list;
    for (NSString *value in values) {
        list.append(ToTagLibString(value));
    }
    _properties.replace(tagLibKey, list);
}

// MARK: - Pictures

- (nullable NSData *)frontCover {
    try {
        const auto pictures = _fileRef->complexProperties("PICTURE");
        if (pictures.isEmpty()) {
            return nil;
        }
        const TagLib::VariantMap *chosen = &pictures.front();
        for (const auto &picture : pictures) {
            if (IsFrontCover(picture)) {
                chosen = &picture;
                break;
            }
        }
        const auto data = chosen->value("data").value<TagLib::ByteVector>();
        if (data.isEmpty()) {
            return nil;
        }
        return [NSData dataWithBytes:data.data() length:data.size()];
    } catch (...) {
        return nil;
    }
}

- (void)setFrontCover:(nullable NSData *)data {
    try {
        const auto existing = _fileRef->complexProperties("PICTURE");
        bool hasFrontCover = false;
        bool hasPictureTypes = false;
        for (const auto &picture : existing) {
            if (picture.contains("pictureType")) {
                hasPictureTypes = true;
                if (IsFrontCover(picture)) {
                    hasFrontCover = true;
                }
            }
        }

        TagLib::List<TagLib::VariantMap> pictures;
        bool isFirst = true;
        for (const auto &picture : existing) {
            bool isFrontCover;
            if (hasFrontCover) {
                isFrontCover = IsFrontCover(picture);
            } else {
                // Formats without picture types (such as MP4) treat the first picture as the cover
                isFrontCover = !hasPictureTypes && isFirst;
            }
            isFirst = false;
            if (!isFrontCover) {
                pictures.append(picture);
            }
        }

        if (data != nil) {
            TagLib::VariantMap picture;
            picture.insert("data", TagLib::ByteVector(static_cast<const char *>(data.bytes),
                                                      static_cast<unsigned int>(data.length)));
            picture.insert("mimeType", ToTagLibString(ImageMimeType(data)));
            picture.insert("description", TagLib::String());
            picture.insert("pictureType", TagLib::String(kFrontCoverType));
            pictures.prepend(picture);
        }
        _fileRef->setComplexProperties("PICTURE", pictures);
    } catch (...) {
    }
}

// MARK: - Saving

- (BOOL)save {
    try {
        const auto unsupported = _fileRef->setProperties(_properties);
        NSMutableArray *unsupportedKeys = [NSMutableArray array];
        for (const auto &[key, values] : unsupported) {
            [unsupportedKeys addObject:ToNSString(key)];
        }
        _unsupportedProperties = unsupportedKeys;
        if (unsupportedKeys.count > 0) {
            NSLog(@"TagLibFile: Properties not supported by this format: %@", unsupportedKeys);
        }

        if (auto *mpegFile = dynamic_cast<TagLib::MPEG::File *>(_fileRef->file())) {
            // Write ID3v2.4, and only update ID3v1 and APE tags if the file already has them
            int tags = TagLib::MPEG::File::ID3v2;
            if (mpegFile->hasID3v1Tag()) {
                tags |= TagLib::MPEG::File::ID3v1;
            }
            if (mpegFile->hasAPETag()) {
                tags |= TagLib::MPEG::File::APE;
            }
            const bool saved = mpegFile->save(tags, TagLib::File::StripNone, TagLib::ID3v2::v4,
                                              TagLib::File::DoNotDuplicate);
            return [self reopen] && saved;
        }
        const bool saved = _fileRef->save();
        return [self reopen] && saved;
    } catch (...) {
        return NO;
    }
}

- (BOOL)removeAllTags {
    try {
        TagLib::File *file = _fileRef->file();
        bool removed;
        if (auto *mpegFile = dynamic_cast<TagLib::MPEG::File *>(file)) {
            removed = mpegFile->strip(TagLib::MPEG::File::AllTags);
        } else if (auto *mp4File = dynamic_cast<TagLib::MP4::File *>(file)) {
            removed = mp4File->strip();
        } else if (auto *flacFile = dynamic_cast<TagLib::FLAC::File *>(file)) {
            flacFile->strip(TagLib::FLAC::File::AllTags);
            flacFile->removePictures();
            removed = flacFile->save();
        } else {
            for (const auto &key : _fileRef->complexPropertyKeys()) {
                _fileRef->setComplexProperties(key, {});
            }
            _fileRef->setProperties(TagLib::PropertyMap());
            removed = _fileRef->save();
        }
        return [self reopen] && removed;
    } catch (...) {
        return NO;
    }
}

+ (NSArray<NSString *> *)supportedExtensions {
    NSMutableArray *extensions = [NSMutableArray array];
    for (const auto &extension : TagLib::FileRef::defaultFileExtensions()) {
        [extensions addObject:ToNSString(extension).lowercaseString];
    }
    return extensions;
}

@end
