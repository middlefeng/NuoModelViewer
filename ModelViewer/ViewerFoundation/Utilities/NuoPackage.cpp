//
//  NuoPackage.cpp
//  ZipTest
//
//  Created by Dong on 11/28/17.
//  Copyright © 2017 Dong. All rights reserved.
//

#include "NuoPackage.h"

#include "assert.h"
#include "zlib.h"



struct __attribute__ ((__packed__)) PackageEndRecord
{
    unsigned int signature;                     // 0x06054b50
    unsigned short diskNumber;                  // unsupported
    unsigned short centralDirectoryDiskNumber;  // unsupported
    unsigned short numEntriesThisDisk;          // unsupported
    unsigned short numEntries;
    unsigned int centralDirectorySize;
    unsigned int centralDirectoryOffset;
    unsigned short zipCommentLength;
    
    // Followed by .ZIP file comment (variable size)
};



struct __attribute__ ((__packed__)) PackageGlobalFileHeader
{
    uint32_t signature;
    uint16_t versionMadeBy;                 // unsupported
    uint16_t versionNeededToExtract;        // unsupported
    uint16_t generalPurposeBitFlag;         // unsupported
    uint16_t compressionMethod;
    uint16_t lastModFileTime;
    uint16_t lastModFileDate;
    uint32_t crc32;
    uint32_t compressedSize;
    uint32_t uncompressedSize;
    uint16_t fileNameLength;
    uint16_t extraFieldLength;              // unsupported
    uint16_t fileCommentLength;             // unsupported
    uint16_t diskNumberStart;               // unsupported
    uint16_t internalFileAttributes;        // unsupported
    uint32_t externalFileAttributes;        // unsupported
    uint32_t relativeOffsetOflocalHeader;
};



struct __attribute__ ((__packed__)) PackageLocalFileHeader
{
    uint32_t signature;
    uint16_t versionNeededToExtract;        // unsupported
    uint16_t generalPurposeBitFlag;         // unsupported
    uint16_t compressionMethod;
    uint16_t lastModFileTime;
    uint16_t lastModFileDate;
    uint32_t crc32;
    uint32_t compressedSize;
    uint32_t uncompressedSize;
    uint16_t fileNameLength;
    uint16_t extraFieldLength;              // unsupported
};



NuoPackage::~NuoPackage()
{
    if (_file)
        fclose(_file);
}



void NuoPackage::open(const std::string& path)
{
    assert(_endRecord == nullptr);
    
    long readBytes, i;
    _file = fopen(path.c_str(), "r");
    
    fseek(_file, 0, SEEK_END);      // go to end of file
    _fileSize = ftell(_file);       // current position equals file size
    
    // fill the buffer, but at most the whole file
    readBytes = (_fileSize < sizeof(_packageBuffer)) ? _fileSize : sizeof(_packageBuffer);
    fseek(_file, _fileSize - readBytes, SEEK_SET);
    fread(_packageBuffer, 1, readBytes, _file);
    
    // naively assume signature can only be found in one place...
    for (i = readBytes - sizeof(PackageEndRecord); i >= 0; i--)
    {
        PackageEndRecord* er = (PackageEndRecord *)(_packageBuffer + i);
        if (er->signature == 0x06054B50)
        {
            _endRecord = std::make_shared<PackageEndRecord>();
            memcpy(_endRecord.get(), er, sizeof(PackageEndRecord));
            break;
        }
    }
}



void NuoPackage::unpackFile(NuoUnpackCallback callback)
{
    if (_endRecord)
        readCentralDirectory(callback, true);
}


void NuoPackage::testFile(NuoUnpackCallback callback)
{
    if (_endRecord)
        readCentralDirectory(callback, false);
}



void NuoPackage::readCentralDirectory(NuoUnpackCallback callback, bool decompressData)
{
    PackageGlobalFileHeader fileHeader;
    
    fseek(_file, _endRecord->centralDirectoryOffset, SEEK_SET);
    for (size_t i = 0; i < _endRecord->numEntries; i++)
    {
        fread(&fileHeader, 1, sizeof(PackageGlobalFileHeader), _file);
        if (fileHeader.signature != 0x02014B50)
        {
            assert(false);
        }
        
        fread(_packageBuffer, 1, fileHeader.fileNameLength, _file);
        _packageBuffer[fileHeader.fileNameLength] = '\0';
        std::string fileName = (char*)_packageBuffer;
        
        if (decompressData)
            readLocalFile(fileHeader, fileName, callback);
        else
            callback(fileName, nullptr, fileHeader.uncompressedSize);
        
        // skip unused fields.
        //
        fseek(_file, fileHeader.extraFieldLength, SEEK_CUR);
        fseek(_file, fileHeader.fileCommentLength, SEEK_CUR);
    }
}



void NuoPackage::readLocalFile(const PackageGlobalFileHeader& fileHeader, const std::string fileName, NuoUnpackCallback callback)
{
    long offset = ftell(_file);
    fseek(_file, fileHeader.relativeOffsetOflocalHeader, SEEK_SET);
    
    PackageLocalFileHeader localHeader;
    
    do
    {
        // local file header
        //
        
        fread(&localHeader, 1, sizeof(PackageLocalFileHeader), _file);
        if (localHeader.signature != 0x04034B50)
        {
            assert(false);
        }
        
        if (fileHeader.uncompressedSize == 0 || fileHeader.compressedSize == 0 ||
            fileName.find("__MACOSX") == 0)
        {
            break;
        }
        
        if (localHeader.fileNameLength)
            fseek(_file, localHeader.fileNameLength, SEEK_CUR);
        
        if (localHeader.extraFieldLength) // skip extra field if there is one
            fseek(_file, localHeader.extraFieldLength, SEEK_CUR);
    
        // read data into buffer and call the outside process function
        //
        
        void* dataBuffer = malloc(fileHeader.uncompressedSize);
        readFileData(fileHeader, dataBuffer);
        
        callback(fileName, dataBuffer, fileHeader.uncompressedSize);
        
        free(dataBuffer);
    }
    while (false);
    
    fseek(_file, offset, SEEK_SET);
}



void NuoPackage::readFileData(const PackageGlobalFileHeader& fileHeader, void* buffer)
{
    if (fileHeader.compressionMethod == 0)
    {
        // store - just read it
        //
        
        if (fread(buffer, 1, fileHeader.uncompressedSize, _file) < fileHeader.uncompressedSize || ferror(_file))
        {
            assert(false);
        }
    }
    else if (fileHeader.compressionMethod == 8)
    {
        // deflate - using zlib
        //
        
        z_stream strm;
        
        strm.zalloc = Z_NULL;
        strm.zfree = Z_NULL;
        strm.opaque = Z_NULL;
        
        strm.avail_in = 0;
        strm.next_in = Z_NULL;
        
        unsigned char *bytes = (unsigned char *)buffer; // cast
        int ret;
        
        // Uue inflateInit2 with negative window bits to indicate raw data
        if ((ret = inflateInit2(&strm, -MAX_WBITS)) != Z_OK)
        {
            assert(false);
        }
        
        long compressedLeft, uncompressedLeft;
        
        // inflate compressed data
        for (compressedLeft = fileHeader.compressedSize, uncompressedLeft = fileHeader.uncompressedSize;
             compressedLeft && uncompressedLeft && ret != Z_STREAM_END; compressedLeft -= strm.avail_in)
        {
            // Read next chunk
            strm.avail_in = (uInt)fread(_packageBuffer, 1,
                                        (sizeof(_packageBuffer) < compressedLeft) ?
                                        sizeof(_packageBuffer) : compressedLeft, _file);
            
            if(strm.avail_in == 0 || ferror(_file))
            {
                inflateEnd(&strm);
                assert(false);
            }
            
            strm.next_in = _packageBuffer;
            strm.avail_out = (uInt)uncompressedLeft;
            strm.next_out = bytes;
            
            compressedLeft -= strm.avail_in; // inflate will change avail_in
            
            ret = inflate(&strm, Z_NO_FLUSH);
            
            if (ret == Z_STREAM_ERROR)
            {
                assert(false);
            }
            
            switch (ret)
            {
                case Z_NEED_DICT:
                    ret = Z_DATA_ERROR;     /* and fall through */
                case Z_DATA_ERROR:
                case Z_MEM_ERROR:
                    inflateEnd(&strm);
                    assert(false);
                default:
                    break;
            }
            
            bytes += uncompressedLeft - strm.avail_out; // bytes uncompressed
            uncompressedLeft = strm.avail_out;
        }
        
        inflateEnd(&strm);
    }
    else
    {
        assert(false);
    }
}




