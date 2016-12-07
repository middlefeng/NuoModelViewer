//
//  NuoTableExporter.cpp
//  ModelViewer
//
//  Created by middleware on 12/6/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#include "NuoTableExporter.h"

#include <memory>


NuoTableExporter::NuoTableExporter()
    : _indent(0)
{
    _result = "return";
}


void NuoTableExporter::StartTable()
{
    AppendByIndent();
    _result = _result + "\n{\n";
    _indent += 4;
}


void NuoTableExporter::StartEntry(const std::string& entryName)
{
    AppendByIndent();
    _result = _result + "\"" + entryName + "\" =";
}


void NuoTableExporter::SetEntryValueFloat(float value)
{
    char* buffer = new char[100];
    snprintf(buffer, 100, "%.2f", value);
    
    _result = _result + buffer + "\n";
    
    delete[] buffer;
}

void NuoTableExporter::SetEntryValueBool(bool value)
{
    const char* buffer = value ? "true" : "false";
    
    _result = _result + buffer + "\n";
    
    delete[] buffer;
}



void NuoTableExporter::SetEntryValueString(const std::string& value)
{
     _result = _result + value + "\n";
}


void NuoTableExporter::EndTable()
{
    _indent -= 4;
    AppendByIndent();
    _result = _result + "}\n";
}



void NuoTableExporter::AppendByIndent()
{
    for (size_t i = 0; i < _indent; ++i)
        _result = _result + " ";
}
