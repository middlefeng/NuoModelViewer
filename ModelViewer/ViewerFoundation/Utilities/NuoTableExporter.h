//
//  NuoTableExporter.hpp
//  ModelViewer
//
//  Created by middleware on 12/6/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#ifndef NuoTableExporter_hpp
#define NuoTableExporter_hpp

#include <stdio.h>
#include <string>
#include <simd/simd.h>

class NuoTableExporter
{
private:
    std::string _result;
    unsigned long _indent;
    
public:
    NuoTableExporter();
    
    void StartTable();
    void StartArrayIndex(size_t index);
    void StartEntry(const std::string& entryName);
    void SetEntryValueFloat(float value);
    void SetEntryValueBool(bool value);
    void SetEntryValueString(const std::string& value);
    void EndTable();
    void EndEntry(bool extraLine);
    
    void SetMatrix(matrix_float4x4 matrix);
    
    const std::string& GetResult() const;

private:
    
    void AppendByIndent();
};

#endif /* NuoTableExporter_hpp */
