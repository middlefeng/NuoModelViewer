//
//  NuoPackage.hpp
//  ZipTest
//
//  Created by Dong on 11/28/17.
//  Copyright © 2017 Dong. All rights reserved.
//

#ifndef NuoPackage_hpp
#define NuoPackage_hpp

#include <stdio.h>
#include <string>
#include <memory>
#include <functional>


struct PackageEndRecord;
struct PackageGlobalFileHeader;
struct PackageLocalFileHeader;



typedef std::function<void(std::string filename, void* buffer, size_t length)> NuoUnpackCallback;


class NuoPackage
{
    
public:
    
    ~NuoPackage();
    
    void open(const std::string& path);
    void unpackFile(NuoUnpackCallback callback);
    void testFile(NuoUnpackCallback callback);

private:
    
    void readCentralDirectory(NuoUnpackCallback callback, bool decompressData);
    void readLocalFile(const PackageGlobalFileHeader& fileHeader, const std::string fileName, NuoUnpackCallback callback);
    void readFileData(const PackageGlobalFileHeader& fileHeader, void* buffer);
    

private:
    
    FILE* _file;
    size_t _fileSize;
    
    std::shared_ptr<PackageEndRecord> _endRecord;
    
    static const size_t kBufferSize { 65536 };
    
    unsigned char _packageBuffer[kBufferSize];
    
};



#endif /* NuoPackage_hpp */
