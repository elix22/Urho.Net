
#pragma once

#include "../Container/Str.h"
#include "../Core/Context.h"


typedef enum Platform
{
    _ANDROID_ =1 ,
    _IOS_,
    TVOS,
    MACOS,
    WINDOWS,
    RASPBERRY_Pi,
    WEB,
    LINUX,
    UNKNOWN
}Platform;

using namespace Urho3D;

String urho3d_get_dotnet_folder();

void urho3d_init_mono(Urho3D::Context* context);
MonoAssembly* urho3d_mono_load_assembly_from_cache(Urho3D::Context* context, const String& p_name, MonoAssemblyName* p_aname, bool p_refonly);
void mono_log_callback(const char *log_domain, const char *log_level, const char *message, mono_bool fatal, void *);

void fixPath(String& path);
String fixPathString(String  path);

bool CopyFileToDocumentsDir(Urho3D::SharedPtr<Urho3D::Context> context_,  String sourceFile , bool overwrite_if_exist = false);
void CopyMonoFilesToDocumentDir(Urho3D::SharedPtr<Urho3D::Context> context,Platform platform);
