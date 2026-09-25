#import "ID3DateWriter.h"

#include <taglib/id3v2tag.h>
#include <taglib/mpegfile.h>
#include <taglib/textidentificationframe.h>

@implementation ID3DateWriter

+ (BOOL)writeDate:(NSString *)date toMP3AtPath:(NSString *)path {
    TagLib::MPEG::File file(path.fileSystemRepresentation, false);
    if (!file.isValid()) {
        return NO;
    }

    auto *tag = file.ID3v2Tag(true);
    if (tag == nullptr) {
        return NO;
    }

    // SFBAudioEngine drops partial dates when writing MP3s. Restore the
    // exact value through the same TagLib dependency it uses for other tags.
    tag->removeFrames("TDRC");
    auto *frame = new TagLib::ID3v2::TextIdentificationFrame("TDRC", TagLib::String::UTF8);
    frame->setText(TagLib::String(date.UTF8String, TagLib::String::UTF8));
    tag->addFrame(frame);

    return file.save(TagLib::MPEG::File::ID3v2,
                     TagLib::MPEG::File::StripNone,
                     TagLib::ID3v2::v4,
                     TagLib::MPEG::File::DoNotDuplicate);
}

@end
