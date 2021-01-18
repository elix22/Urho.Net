/*************************************************************************/
/*  ios_support.mm                                                       */
/*************************************************************************/
/*                       This file is part of:                           */
/*                           GODOT ENGINE                                */
/*                      https://godotengine.org                          */
/*************************************************************************/
/* Copyright (c) 2007-2020 Juan Linietsky, Ariel Manzur.                 */
/* Copyright (c) 2014-2020 Godot Engine contributors (cf. AUTHORS.md).   */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the       */
/* "Software"), to deal in the Software without restriction, including   */
/* without limitation the rights to use, copy, modify, merge, publish,   */
/* distribute, sublicense, and/or sell copies of the Software, and to    */
/* permit persons to whom the Software is furnished to do so, subject to */
/* the following conditions:                                             */
/*                                                                       */
/* The above copyright notice and this permission notice shall be        */
/* included in all copies or substantial portions of the Software.       */
/*                                                                       */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
/*************************************************************************/

#include "ios_support.h"

#ifndef _TESTCASE_
#include <mono/jit/jit.h>
#endif

#include <mono/metadata/environment.h>
#include <mono/utils/mono-publib.h>
#include <mono/metadata/mono-config.h>
#include <mono/metadata/assembly.h>

#if  defined(IOS) || defined(TVOS)

#import <Foundation/Foundation.h>
#include <os/log.h>

//#include "core/ustring.h"


#include <sys/stat.h>
#include <sys/mman.h>

static os_log_t stdout_log;

typedef unsigned char* (*MonoLoadAotDataFunc)          (MonoAssembly *assembly, int size, void* user_data, void **out_handle);
typedef void  (*MonoFreeAotDataFunc)          (MonoAssembly *assembly, int size, void* user_data, void *handle);
void
mono_install_load_aot_data_hook (MonoLoadAotDataFunc load_func, MonoFreeAotDataFunc free_func, void* user_data);

// no-op for iOS and tvOS.
// watchOS is not supported yet.
#define MONO_ENTER_GC_UNSAFE
#define MONO_EXIT_GC_UNSAFE


bool
file_exists (const char *path)
{
    struct stat buffer;
    return stat (path, &buffer) == 0;
}

static char *bundle_path;

const char *
get_bundle_path (void)
{
    if (bundle_path)
        return bundle_path;

    NSBundle *main_bundle = [NSBundle mainBundle];
    NSString *path;
    char *result;

    path = [main_bundle bundlePath];
    bundle_path = strdup ([path UTF8String]);

    return bundle_path;
}

static unsigned char *
load_aot_data (MonoAssembly *assembly, int size, void *user_data, void **out_handle)
{
    *out_handle = NULL;

    char path [1024];
    int res;

    MonoAssemblyName *assembly_name = mono_assembly_get_name (assembly);
    const char *aname = mono_assembly_name_get_name (assembly_name);
    const char *bundle = get_bundle_path ();

    os_log_info (OS_LOG_DEFAULT, "Looking for aot data for assembly '%s'.", aname);
    res = snprintf (path, sizeof (path) - 1, "%s/%s.aotdata", bundle, aname);
    assert (res > 0);

    int fd = open (path, O_RDONLY);
    if (fd < 0) {
        os_log_info (OS_LOG_DEFAULT, "Could not load the aot data for %s from %s: %s\n", aname, path, strerror (errno));
        return NULL;
    }

    void *ptr = mmap (NULL, size, PROT_READ, MAP_FILE | MAP_PRIVATE, fd, 0);
    if (ptr == MAP_FAILED) {
        os_log_info (OS_LOG_DEFAULT, "Could not map the aot file for %s: %s\n", aname, strerror (errno));
        close (fd);
        return NULL;
    }

    close (fd);

    os_log_info (OS_LOG_DEFAULT, "Loaded aot data for %s.\n", aname);

    *out_handle = ptr;

    return (unsigned char *) ptr;
}


static void
free_aot_data (MonoAssembly *assembly, int size, void *user_data, void *handle)
{
    munmap (handle, size);
}

static MonoAssembly*
load_assembly (const char *name, const char *culture)
{
    const char *bundle = get_bundle_path ();
    char filename [1024];
    char path [1024];
    int res;

    os_log_info (OS_LOG_DEFAULT, "assembly_preload_hook: %{public}s %{public}s %{public}s\n", name, culture, bundle);

    int len = strlen (name);
    int has_extension = len > 3 && name [len - 4] == '.' && (!strcmp ("exe", name + (len - 3)) || !strcmp ("dll", name + (len - 3)));

    // add extensions if required.
    strlcpy (filename, name, sizeof (filename));
    if (!has_extension) {
        strlcat (filename, ".dll", sizeof (filename));
    }

    if (culture && strcmp (culture, ""))
        res = snprintf (path, sizeof (path) - 1, "%s/%s/%s", bundle, culture, filename);
    else
        res = snprintf (path, sizeof (path) - 1, "%s/%s", bundle, filename);
    assert (res > 0);

    if (file_exists (path)) {
        MonoAssembly *assembly = mono_assembly_open (path, NULL);
        assert (assembly);
        return assembly;
    }
    return NULL;
}

static MonoAssembly*
assembly_preload_hook (MonoAssemblyName *aname, char **assemblies_path, void* user_data)
{
    const char *name = mono_assembly_name_get_name (aname);
    const char *culture = mono_assembly_name_get_culture (aname);

    return load_assembly (name, culture);
}

char *
strdup_printf (const char *msg, ...)
{
    va_list args;
    char *formatted = NULL;

    va_start (args, msg);
    vasprintf (&formatted, msg, args);
    va_end (args);

    return formatted;
}

static MonoObject *
fetch_exception_property (MonoObject *obj, const char *name, bool is_virtual)
{
    MonoMethod *get = NULL;
    MonoMethod *get_virt = NULL;
    MonoObject *exc = NULL;

    get = mono_class_get_method_from_name (mono_get_exception_class (), name, 0);
    if (get) {
        if (is_virtual) {
            get_virt = mono_object_get_virtual_method (obj, get);
            if (get_virt)
                get = get_virt;
        }

        return (MonoObject *) mono_runtime_invoke (get, obj, NULL, &exc);
    } else {
        os_log_error (OS_LOG_DEFAULT, "Could not find the property System.Exception.%{public}s.", name);
    }

    return NULL;
}

static char *
fetch_exception_property_string (MonoObject *obj, const char *name, bool is_virtual)
{
    MonoString *str = (MonoString *) fetch_exception_property (obj, name, is_virtual);
    return str ? mono_string_to_utf8 (str) : NULL;
}

void
unhandled_exception_handler (MonoObject *exc, void *user_data)
{
    NSMutableString *msg = [[NSMutableString alloc] init];

    MonoClass *type = mono_object_get_class (exc);
    char *type_name = strdup_printf ("%s.%s", mono_class_get_namespace (type), mono_class_get_name (type));
    char *trace = fetch_exception_property_string (exc, "get_StackTrace", true);
    char *message = fetch_exception_property_string (exc, "get_Message", true);

    [msg appendString:@"Unhandled managed exception:\n"];
    [msg appendFormat: @"%s (%s)\n%s\n", message, type_name, trace ? trace : ""];

    free (trace);
    free (message);
    free (type_name);

    os_log_info (OS_LOG_DEFAULT, "%@", msg);
    os_log_info (OS_LOG_DEFAULT, "Exit code: %d.", 1);
    exit (1);
}

void
log_callback (const char *log_domain, const char *log_level, const char *message, mono_bool fatal, void *user_data)
{
    os_log_info (OS_LOG_DEFAULT, "(%s %s) %s", log_domain, log_level, message);
    //NSLog (@"(%s %s) %s", log_domain, log_level, message);
    if (fatal) {
        os_log_info (OS_LOG_DEFAULT, "Exit code: %d.", 1);
        exit (1);
    }
}

static void
register_dllmap (void)
{
    mono_dllmap_insert (NULL, "System.Native", NULL, "__Internal", NULL);
    mono_dllmap_insert (NULL, "System.IO.Compression.Native", NULL, "__Internal", NULL);
    mono_dllmap_insert (NULL, "System.Security.Cryptography.Native.Apple", NULL, "__Internal", NULL);
}


// Implemented mostly following: https://github.com/mono/mono/blob/master/sdks/ios/app/runtime.m

// Definition generated by the Godot exporter
extern "C" void urho_mono_setup_aot();
/* Implemented by generated code */
void mono_ios_register_modules (void);
void mono_ios_setup_execution_mode (void);


namespace ios {
namespace support {

extern "C" {
//xcode-select --print-path
// /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS13.5.sdk -Qunused-arguments -miphoneos-version-min=10.0  -arch arm64 -c -o mscorlib.dll.o -x assembler mscorlib.dll.s
// other flags direct-icalls
/*IOS requires special handling , it is not allowed to use JIT , only AOT is allowed
 So all the assemblies are compiled AOT into ARM64 assmebler code and integrated into the project.
 export MONO_PATH=/Users/elialoni/Urho3D-Dev/mono-poc/Urho3D/Mono/bcl/monotouch
./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-pinvoke,static,mtriple=arm64-ios  -O=gsharedvt   04_StaticScene.exe
 ./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-pinvoke,static,mtriple=arm64-ios  -O=gsharedvt   DotNetBindings.dll
 ./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-pinvoke,static,mtriple=arm64-ios  -O=gsharedvt   ../../bcl/monotouch/mscorlib.dll
*/

// batch compilation
// for i in ../../bcl/monotouch/*.dll; do ./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-pinvoke,static,mtriple=arm64-ios  -O=gsharedvt  $i; done
// for i in ../../bcl/monotouch/Facades/*.dll; do ./aarch64-apple-darwin-mono-sgen   --aot=asmonly,full,direct-pinvoke,static,mtriple=arm64-ios  -O=gsharedvt  $i; done


extern void * mono_aot_module_Game_info;
extern void * mono_aot_module_UrhoDotNet_info;


extern void *mono_aot_module_mscorlib_info;
extern void *mono_aot_module_System_info;
extern void *mono_aot_module_System_Core_info;
extern void *mono_aot_module_System_Xml_info;

extern void *mono_aot_module_Mono_Security_info;
extern void *mono_aot_module_System_Numerics_info;

//extern void *mono_aot_module_Xamarin_iOS_info;
//
/*
extern void *mono_aot_module_netstandard_info;




extern void *mono_aot_module_System_Data_info;
extern void *mono_aot_module_System_Transactions_info;
extern void *mono_aot_module_System_Data_DataSetExtensions_info;
extern void *mono_aot_module_System_Drawing_Common_info;
extern void *mono_aot_module_System_IO_Compression_info;
extern void *mono_aot_module_System_IO_Compression_FileSystem_info;
extern void *mono_aot_module_System_ComponentModel_Composition_info;
 */
//extern void *mono_aot_module_Xamarin_iOS_info;

} // extern "C"

void urho_mono_setup_aot() {
    mono_aot_register_module((void **)mono_aot_module_Game_info);
    mono_aot_register_module((void **)mono_aot_module_UrhoDotNet_info);

    mono_aot_register_module((void **)mono_aot_module_mscorlib_info);
    mono_aot_register_module((void **)mono_aot_module_System_info);
    mono_aot_register_module((void **)mono_aot_module_System_Core_info);
    mono_aot_register_module((void **)mono_aot_module_System_Xml_info);
    
    mono_aot_register_module((void **)mono_aot_module_Mono_Security_info);
    mono_aot_register_module((void **)mono_aot_module_System_Numerics_info);
    /*
    mono_aot_register_module((void **)mono_aot_module_netstandard_info);
  
    mono_aot_register_module((void **)mono_aot_module_System_Data_info);
    mono_aot_register_module((void **)mono_aot_module_System_Transactions_info);
    mono_aot_register_module((void **)mono_aot_module_System_Data_DataSetExtensions_info);
    mono_aot_register_module((void **)mono_aot_module_System_Drawing_Common_info);
    mono_aot_register_module((void **)mono_aot_module_System_IO_Compression_info);
    mono_aot_register_module((void **)mono_aot_module_System_IO_Compression_FileSystem_info);
    mono_aot_register_module((void **)mono_aot_module_System_ComponentModel_Composition_info);
     */
    //mono_aot_register_module((void **)mono_aot_module_Xamarin_iOS_info);
    
    mono_jit_set_aot_mode(MONO_AOT_MODE_FULL);
} // urho_mono_setup_aot


void register_arkit_types() { /*stub*/ };
void unregister_arkit_types() { /*stub*/ };
void register_camera_types() { /*stub*/ };
void unregister_camera_types() { /*stub*/ };

void ios_mono_log_callback(const char *log_domain, const char *log_level, const char *message, mono_bool fatal, void *user_data) {
	os_log_info(OS_LOG_DEFAULT, "(%s %s) %s", log_domain, log_level, message);
	if (fatal) {
		os_log_info(OS_LOG_DEFAULT, "Exit code: %d.", 1);
		exit(1);
	}
}

void initialize() {
	mono_dllmap_insert(NULL, "System.Native", NULL, "__Internal", NULL);
	mono_dllmap_insert(NULL, "System.IO.Compression.Native", NULL, "__Internal", NULL);
	mono_dllmap_insert(NULL, "System.Security.Cryptography.Native.Apple", NULL, "__Internal", NULL);

	urho_mono_setup_aot();
    
//    mono_install_assembly_preload_hook (assembly_preload_hook, NULL);
  //  mono_install_load_aot_data_hook (load_aot_data, free_aot_data, NULL);
    
	mono_set_signal_chaining(true);
	mono_set_crash_chaining(true);
}

void cleanup() {
}

} // namespace support
} // namespace ios


// The following are P/Invoke functions required by the monotouch profile of the BCL.
// These are P/Invoke functions and not internal calls, hence why they use
// 'mono_bool' and 'const char*' instead of 'MonoBoolean' and 'MonoString*'.

#define GD_PINVOKE_EXPORT extern "C" __attribute__((visibility("default")))

GD_PINVOKE_EXPORT const char *xamarin_get_locale_country_code() {
	NSLocale *locale = [NSLocale currentLocale];
	NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
	if (countryCode == NULL) {
		return strdup("US");
	}
	return strdup([countryCode UTF8String]);
}

GD_PINVOKE_EXPORT void xamarin_log(const uint16_t *p_unicode_message) {
	int length = 0;
	const uint16_t *ptr = p_unicode_message;
	while (*ptr++)
		length += sizeof(uint16_t);
	NSString *msg = [[NSString alloc] initWithBytes:p_unicode_message length:length encoding:NSUTF16LittleEndianStringEncoding];

	os_log_info(OS_LOG_DEFAULT, "%{public}@", msg);
}

GD_PINVOKE_EXPORT const char *xamarin_GetFolderPath(int p_folder) {
	NSSearchPathDirectory dd = (NSSearchPathDirectory)p_folder;
	NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:dd inDomains:NSUserDomainMask] lastObject];
	NSString *path = [url path];
	return strdup([path UTF8String]);
}

GD_PINVOKE_EXPORT char *xamarin_timezone_get_local_name() {
	NSTimeZone *tz = nil;
	tz = [NSTimeZone localTimeZone];
	NSString *name = [tz name];
	return (name != nil) ? strdup([name UTF8String]) : strdup("Local");
}

GD_PINVOKE_EXPORT char **xamarin_timezone_get_names(uint32_t *p_count) {
	NSArray *array = [NSTimeZone knownTimeZoneNames];
	*p_count = (uint32_t)array.count;
	char **result = (char **)malloc(sizeof(char *) * (*p_count));
	for (uint32_t i = 0; i < *p_count; i++) {
		NSString *s = [array objectAtIndex:i];
		result[i] = strdup(s.UTF8String);
	}
	return result;
}

GD_PINVOKE_EXPORT void *xamarin_timezone_get_data(const char *p_name, uint32_t *p_size) { // FIXME: uint32_t since Dec 2019, unsigned long before
	NSTimeZone *tz = nil;
	if (p_name) {
		NSString *n = [[NSString alloc] initWithUTF8String:p_name];
		tz = [[NSTimeZone alloc] initWithName:n];
	} else {
		tz = [NSTimeZone localTimeZone];
	}
	NSData *data = [tz data];
	*p_size = (uint32_t)[data length];
	void *result = malloc(*p_size);
	memcpy(result, data.bytes, *p_size);
	return result;
}

GD_PINVOKE_EXPORT void xamarin_start_wwan(const char *p_uri) {
	// FIXME: What's this for? No idea how to implement.
	os_log_error(OS_LOG_DEFAULT, "Not implemented: 'xamarin_start_wwan'");
}

#endif // IPHONE_ENABLED
