// Possible defines:
//	CHDebug           if defined, CHDebugLog is equivalent to CHLog; else, emits no code
//	CHUseSubstrate    if defined, uses MSMessageHookEx to hook methods, otherwise uses internal hooking routines. Warning! super call closures are only available on ARM platforms for recent releases of MobileSubstrate
//	CHEnableProfiling if defined, enables calls to CHProfileScope()
//  CHAppName         should be set to the name of the application (if not, defaults to "CaptainHook"); used for logging and profiling

#import <objc/runtime.h>
#import <objc/message.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSObjCRuntime.h>

#ifndef CHAppName
#define CHAppName "CaptainHook"
#endif

#ifdef __clang__
#if __has_feature(objc_arc)
#define CHHasARC
#endif
#endif

// Some Debugging/Logging Commands

#define CHStringify_(x) #x
#define CHStringify(x) CHStringify_(x)
#define CHConcat_(a, b) a ## b
#define CHConcat(a, b) CHConcat_(a, b)

#define CHNothing() do { } while(0)

#define CHLocationInSource [NSString stringWithFormat:@CHStringify(__LINE__) " in %s", __FUNCTION__]

#define CHLog(args...)			NSLog(@CHAppName ": %@", [NSString stringWithFormat:args])
#define CHLogSource(args...)	NSLog(@CHAppName " @ " CHStringify(__LINE__) " in %s: %@", __FUNCTION__, [NSString stringWithFormat:args])

#ifdef CHDebug
	#define CHDebugLog(args...)			CHLog(args)
	#define CHDebugLogSource(args...)	CHLogSource(args)
#else
	#define CHDebugLog(args...)			CHNothing()
	#define CHDebugLogSource(args...)	CHNothing()
#endif

// Constructor
#define CHConstructor static __attribute__((constructor)) void CHConcat(CHConstructor, __LINE__)()
#define CHInline inline __attribute__((always_inline))

// Cached Class Declaration (allows hooking methods, and fast lookup of classes)
struct CHClassDeclaration_ {
	Class class_;
	Class metaClass_;
	Class superClass_;
};
typedef struct CHClassDeclaration_ CHClassDeclaration_;
#define CHDeclareClass(name) \
	@class name; \
	static CHClassDeclaration_ name ## $;

// Loading Cached Classes (use CHLoadClass when class is linkable, CHLoadLateClass when it isn't)
static inline Class CHLoadClass_(CHClassDeclaration_ *declaration, Class value)
{
	declaration->class_ = value;
	declaration->metaClass_ = object_getClass(value);
	declaration->superClass_ = class_getSuperclass(value);
	return value;
}
#define CHLoadLateClass(name) CHLoadClass_(&name ## $, objc_getClass(#name))
#define CHLoadClass(name) CHLoadClass_(&name ## $, [name class])

// Quick Lookup of cached classes, and common methods on them
#define CHClass(name) name ## $.class_
#define CHMetaClass(name) name ## $.metaClass_
#define CHSuperClass(name) name ## $.superClass_
#define CHAlloc(name) ((name *)[CHClass(name) alloc])
#define CHSharedInstance(name) ((name *)[CHClass(name) sharedInstance])
#define CHIsClass(obj, name) [obj isKindOfClass:CHClass(name)]
#define CHRespondsTo(obj, sel) [obj respondsToSelector:@selector(sel)]

// Replacement Method Definition
#define CHDeclareSig0_(return_type) \
	const char *return_ = @encode(return_type); \
	size_t return_len = __builtin_strlen(return_); \
	char sig[return_len+2+1]; \
	__builtin_memcpy(sig, return_, return_len); \
	sig[return_len] = _C_ID; \
	sig[return_len+1] = _C_SEL; \
	sig[return_len+2] = '\0';
#define CHDeclareSig1_(return_type, type1) \
	const char *return_ = @encode(return_type); \
	size_t return_len = __builtin_strlen(return_); \
	const char *type1_ = @encode(type1); \
	size_t type1_len = __builtin_strlen(type1_); \
	char sig[return_len+2+type1_len+1]; \
	__builtin_memcpy(sig, return_, return_len); \
	sig[return_len] = _C_ID; \
	sig[return_len+1] = _C_SEL; \
	__builtin_memcpy(&sig[return_len+2], type1_, type1_len); \
	sig[return_len+type1_len+2] = '\0';
#define CHDeclareSig2_(return_type, type1, type2) \
	const char *return_ = @encode(return_type); \
	size_t return_len = __builtin_strlen(return_); \
	const char *type1_ = @encode(type1); \
	size_t type1_len = __builtin_strlen(type1_); \
	const char *type2_ = @encode(type2); \
	size_t type2_len = __builtin_strlen(type2_); \
	char sig[return_len+2+type1_len+type2_len+1]; \
	__builtin_memcpy(sig, return_, return_len); \
	sig[return_len] = _C_ID; \
	sig[return_len+1] = _C_SEL; \
	__builtin_memcpy(&sig[return_len+2], type1_, type1_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len], type2_, type2_len); \
	sig[return_len+type1_len+type2_len+2] = '\0';
#define CHDeclareSig3_(return_type, type1, type2, type3) \
	const char *return_ = @encode(return_type); \
	size_t return_len = __builtin_strlen(return_); \
	const char *type1_ = @encode(type1); \
	size_t type1_len = __builtin_strlen(type1_); \
	const char *type2_ = @encode(type2); \
	size_t type2_len = __builtin_strlen(type2_); \
	const char *type3_ = @encode(type3); \
	size_t type3_len = __builtin_strlen(type3_); \
	char sig[return_len+2+type1_len+type2_len+type3_len+1]; \
	__builtin_memcpy(sig, return_, return_len); \
	sig[return_len] = _C_ID; \
	sig[return_len+1] = _C_SEL; \
	__builtin_memcpy(&sig[return_len+2], type1_, type1_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len], type2_, type2_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len], type3_, type3_len); \
	sig[return_len+type1_len+type2_len+type3_len+2] = '\0';
#define CHDeclareSig4_(return_type, type1, type2, type3, type4) \
	const char *return_ = @encode(return_type); \
	size_t return_len = __builtin_strlen(return_); \
	const char *type1_ = @encode(type1); \
	size_t type1_len = __builtin_strlen(type1_); \
	const char *type2_ = @encode(type2); \
	size_t type2_len = __builtin_strlen(type2_); \
	const char *type3_ = @encode(type3); \
	size_t type3_len = __builtin_strlen(type3_); \
	const char *type4_ = @encode(type4); \
	size_t type4_len = __builtin_strlen(type4_); \
	char sig[return_len+2+type1_len+type2_len+type3_len+type4_len+1]; \
	__builtin_memcpy(sig, return_, return_len); \
	sig[return_len] = _C_ID; \
	sig[return_len+1] = _C_SEL; \
	__builtin_memcpy(&sig[return_len+2], type1_, type1_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len], type2_, type2_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len], type3_, type3_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len], type4_, type4_len); \
	sig[return_len+type1_len+type2_len+type3_len+type4_len+2] = '\0';
#define CHDeclareSig5_(return_type, type1, type2, type3, type4, type5) \
	const char *return_ = @encode(return_type); \
	size_t return_len = __builtin_strlen(return_); \
	const char *type1_ = @encode(type1); \
	size_t type1_len = __builtin_strlen(type1_); \
	const char *type2_ = @encode(type2); \
	size_t type2_len = __builtin_strlen(type2_); \
	const char *type3_ = @encode(type3); \
	size_t type3_len = __builtin_strlen(type3_); \
	const char *type4_ = @encode(type4); \
	size_t type4_len = __builtin_strlen(type4_); \
	const char *type5_ = @encode(type5); \
	size_t type5_len = __builtin_strlen(type5_); \
	char sig[return_len+2+type1_len+type2_len+type3_len+type4_len+type5_len+1]; \
	__builtin_memcpy(sig, return_, return_len); \
	sig[return_len] = _C_ID; \
	sig[return_len+1] = _C_SEL; \
	__builtin_memcpy(&sig[return_len+2], type1_, type1_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len], type2_, type2_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len], type3_, type3_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len], type4_, type4_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len+type4_len], type5_, type5_len); \
	sig[return_len+type1_len+type2_len+type3_len+type4_len+type5_len+2] = '\0';
#define CHDeclareSig6_(return_type, type1, type2, type3, type4, type5, type6) \
	const char *return_ = @encode(return_type); \
	size_t return_len = __builtin_strlen(return_); \
	const char *type1_ = @encode(type1); \
	size_t type1_len = __builtin_strlen(type1_); \
	const char *type2_ = @encode(type2); \
	size_t type2_len = __builtin_strlen(type2_); \
	const char *type3_ = @encode(type3); \
	size_t type3_len = __builtin_strlen(type3_); \
	const char *type4_ = @encode(type4); \
	size_t type4_len = __builtin_strlen(type4_); \
	const char *type5_ = @encode(type5); \
	size_t type5_len = __builtin_strlen(type5_); \
	const char *type6_ = @encode(type6); \
	size_t type6_len = __builtin_strlen(type6_); \
	char sig[return_len+2+type1_len+type2_len+type3_len+type4_len+type5_len+type6_len+1]; \
	__builtin_memcpy(sig, return_, return_len); \
	sig[return_len] = _C_ID; \
	sig[return_len+1] = _C_SEL; \
	__builtin_memcpy(&sig[return_len+2], type1_, type1_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len], type2_, type2_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len], type3_, type3_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len], type4_, type4_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len+type4_len], type5_, type5_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len+type4_len+type5_len], type6_, type6_len); \
	sig[return_len+type1_len+type2_len+type3_len+type4_len+type5_len+type6_len+2] = '\0';
#define CHDeclareSig7_(return_type, type1, type2, type3, type4, type5, type6, type7) \
	const char *return_ = @encode(return_type); \
	size_t return_len = __builtin_strlen(return_); \
	const char *type1_ = @encode(type1); \
	size_t type1_len = __builtin_strlen(type1_); \
	const char *type2_ = @encode(type2); \
	size_t type2_len = __builtin_strlen(type2_); \
	const char *type3_ = @encode(type3); \
	size_t type3_len = __builtin_strlen(type3_); \
	const char *type4_ = @encode(type4); \
	size_t type4_len = __builtin_strlen(type4_); \
	const char *type5_ = @encode(type5); \
	size_t type5_len = __builtin_strlen(type5_); \
	const char *type6_ = @encode(type6); \
	size_t type6_len = __builtin_strlen(type6_); \
	const char *type7_ = @encode(type7); \
	size_t type7_len = __builtin_strlen(type7_); \
	char sig[return_len+2+type1_len+type2_len+type3_len+type4_len+type5_len+type6_len+type7_len+1]; \
	__builtin_memcpy(sig, return_, return_len); \
	sig[return_len] = _C_ID; \
	sig[return_len+1] = _C_SEL; \
	__builtin_memcpy(&sig[return_len+2], type1_, type1_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len], type2_, type2_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len], type3_, type3_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len], type4_, type4_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len+type4_len], type5_, type5_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len+type4_len+type5_len], type6_, type6_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len+type4_len+type5_len+type6_len], type7_, type7_len); \
	sig[return_len+type1_len+type2_len+type3_len+type4_len+type5_len+type6_len+type7_len+2] = '\0';
#define CHDeclareSig8_(return_type, type1, type2, type3, type4, type5, type6, type7, type8) \
	const char *return_ = @encode(return_type); \
	size_t return_len = __builtin_strlen(return_); \
	const char *type1_ = @encode(type1); \
	size_t type1_len = __builtin_strlen(type1_); \
	const char *type2_ = @encode(type2); \
	size_t type2_len = __builtin_strlen(type2_); \
	const char *type3_ = @encode(type3); \
	size_t type3_len = __builtin_strlen(type3_); \
	const char *type4_ = @encode(type4); \
	size_t type4_len = __builtin_strlen(type4_); \
	const char *type5_ = @encode(type5); \
	size_t type5_len = __builtin_strlen(type5_); \
	const char *type6_ = @encode(type6); \
	size_t type6_len = __builtin_strlen(type6_); \
	const char *type7_ = @encode(type7); \
	size_t type7_len = __builtin_strlen(type7_); \
	const char *type8_ = @encode(type8); \
	size_t type8_len = __builtin_strlen(type8_); \
	char sig[return_len+2+type1_len+type2_len+type3_len+type4_len+type5_len+type6_len+type7_len+type8_len+1]; \
	__builtin_memcpy(sig, return_, return_len); \
	sig[return_len] = _C_ID; \
	sig[return_len+1] = _C_SEL; \
	__builtin_memcpy(&sig[return_len+2], type1_, type1_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len], type2_, type2_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len], type3_, type3_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len], type4_, type4_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len+type4_len], type5_, type5_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len+type4_len+type5_len], type6_, type6_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len+type4_len+type5_len+type6_len], type7_, type7_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len+type4_len+type5_len+type6_len+type7_len], type8_, type8_len); \
	sig[return_len+type1_len+type2_len+type3_len+type4_len+type5_len+type6_len+type7_len+type8_len+2] = '\0';
#define CHDeclareSig9_(return_type, type1, type2, type3, type4, type5, type6, type7, type8, type9) \
	const char *return_ = @encode(return_type); \
	size_t return_len = __builtin_strlen(return_); \
	const char *type1_ = @encode(type1); \
	size_t type1_len = __builtin_strlen(type1_); \
	const char *type2_ = @encode(type2); \
	size_t type2_len = __builtin_strlen(type2_); \
	const char *type3_ = @encode(type3); \
	size_t type3_len = __builtin_strlen(type3_); \
	const char *type4_ = @encode(type4); \
	size_t type4_len = __builtin_strlen(type4_); \
	const char *type5_ = @encode(type5); \
	size_t type5_len = __builtin_strlen(type5_); \
	const char *type6_ = @encode(type6); \
	size_t type6_len = __builtin_strlen(type6_); \
	const char *type7_ = @encode(type7); \
	size_t type7_len = __builtin_strlen(type7_); \
	const char *type8_ = @encode(type8); \
	size_t type8_len = __builtin_strlen(type8_); \
	const char *type9_ = @encode(type9); \
	size_t type9_len = __builtin_strlen(type9_); \
	char sig[return_len+2+type1_len+type2_len+type3_len+type4_len+type5_len+type6_len+type7_len+type8_len+type9_len+1]; \
	__builtin_memcpy(sig, return_, return_len); \
	sig[return_len] = _C_ID; \
	sig[return_len+1] = _C_SEL; \
	__builtin_memcpy(&sig[return_len+2], type1_, type1_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len], type2_, type2_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len], type3_, type3_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len], type4_, type4_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len+type4_len], type5_, type5_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len+type4_len+type5_len], type6_, type6_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len+type4_len+type5_len+type6_len], type7_, type7_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len+type4_len+type5_len+type6_len+type7_len], type8_, type8_len); \
	__builtin_memcpy(&sig[return_len+2+type1_len+type2_len+type3_len+type4_len+type5_len+type6_len+type7_len+type8_len], type9_, type9_len); \
	sig[return_len+type1_len+type2_len+type3_len+type4_len+type5_len+type6_len+type7_len+type8_len+type9_len+2] = '\0';
	
#ifdef CHUseSubstrate
#import <substrate.h>
#define CHMethod_(return_type, class_type, class_name, class_val, super_class_val, name, sel, sigdef, supercall, args...) \
	static return_type (*$ ## class_name ## _ ## name ## _super)(class_type self, SEL _cmd, ##args); \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args); \
	__attribute__((always_inline)) \
	static inline void $ ## class_name ## _ ## name ## _register() { \
		if (class_val) { \
			MSHookMessageEx(class_val, @selector(sel), (IMP)&$ ## class_name ## _ ## name ## _method, (IMP *)&$ ## class_name ## _ ## name ## _super); \
			if (!$ ## class_name ## _ ## name ## _super) { \
				sigdef; \
				class_addMethod(class_val, @selector(sel), (IMP)&$ ## class_name ## _ ## name ## _method, sig); \
			} \
		} \
	} \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args)
#define CHMethod_new_(return_type, class_type, class_name, class_val, super_class_val, name, sel, sigdef, supercall, args...) \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args); \
	__attribute__((always_inline)) \
	static inline void $ ## class_name ## _ ## name ## _register() { \
		sigdef; \
		class_addMethod(class_val, @selector(sel), (IMP)&$ ## class_name ## _ ## name ## _method, sig); \
	} \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args)
#define CHMethod_super_(return_type, class_type, class_name, class_val, super_class_val, name, sel, sigdef, supercall, args...) \
	static return_type (*$ ## class_name ## _ ## name ## _super)(class_type self, SEL _cmd, ##args); \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args); \
	__attribute__((always_inline)) \
	static inline void $ ## class_name ## _ ## name ## _register() { \
		if (class_val) { \
			MSHookMessageEx(class_val, @selector(sel), (IMP)&$ ## class_name ## _ ## name ## _method, (IMP *)&$ ## class_name ## _ ## name ## _super); \
		} \
	} \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args)
#define CHMethod_self_(return_type, class_type, class_name, class_val, super_class_val, name, sel, sigdef, supercall, args...) \
	static return_type (*$ ## class_name ## _ ## name ## _super)(class_type self, SEL _cmd, ##args); \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args); \
	__attribute__((always_inline)) \
	static inline void $ ## class_name ## _ ## name ## _register() { \
		if (class_val) { \
			MSHookMessageEx(class_val, @selector(sel), (IMP)&$ ## class_name ## _ ## name ## _method, (IMP *)&$ ## class_name ## _ ## name ## _super); \
		} \
	} \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args)
#else
#define CHMethod_(return_type, class_type, class_name, class_val, super_class_val, name, sel, sigdef, supercall, args...) \
	static return_type (*$ ## class_name ## _ ## name ## _super)(class_type self, SEL _cmd, ##args); \
	static return_type $ ## class_name ## _ ## name ## _closure(class_type self, SEL _cmd, ##args) { \
		typedef return_type (*supType)(class_type, SEL, ## args); \
		supType supFn = (supType)class_getMethodImplementation(super_class_val, _cmd); \
		return supFn supercall; \
	} \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args); \
	__attribute__((always_inline)) \
	static inline void $ ## class_name ## _ ## name ## _register() { \
		Method method = class_getInstanceMethod(class_val, @selector(sel)); \
		if (method) { \
			$ ## class_name ## _ ## name ## _super = (__typeof__($ ## class_name ## _ ## name ## _super))method_getImplementation(method); \
			if (class_addMethod(class_val, @selector(sel), (IMP)&$ ## class_name ## _ ## name ## _method, method_getTypeEncoding(method))) { \
				$ ## class_name ## _ ## name ## _super = &$ ## class_name ## _ ## name ## _closure; \
			} else { \
				method_setImplementation(method, (IMP)&$ ## class_name ## _ ## name ## _method); \
			} \
		} else { \
			sigdef; \
			class_addMethod(class_val, @selector(sel), (IMP)&$ ## class_name ## _ ## name ## _method, sig); \
		} \
	} \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args)
#define CHMethod_new_(return_type, class_type, class_name, class_val, super_class_val, name, sel, sigdef, supercall, args...) \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args); \
	__attribute__((always_inline)) \
	static inline void $ ## class_name ## _ ## name ## _register() { \
		sigdef; \
		class_addMethod(class_val, @selector(sel), (IMP)&$ ## class_name ## _ ## name ## _method, sig); \
	} \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args)
#define CHMethod_super_(return_type, class_type, class_name, class_val, super_class_val, name, sel, sigdef, supercall, args...) \
	static return_type (*$ ## class_name ## _ ## name ## _super)(class_type self, SEL _cmd, ##args); \
	static return_type $ ## class_name ## _ ## name ## _closure(class_type self, SEL _cmd, ##args) { \
		typedef return_type (*supType)(class_type, SEL, ## args); \
		supType supFn = (supType)class_getMethodImplementation(super_class_val, _cmd); \
		return supFn supercall; \
	} \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args); \
	__attribute__((always_inline)) \
	static inline void $ ## class_name ## _ ## name ## _register() { \
		Method method = class_getInstanceMethod(class_val, @selector(sel)); \
		if (method) { \
			$ ## class_name ## _ ## name ## _super = (__typeof__($ ## class_name ## _ ## name ## _super))method_getImplementation(method); \
			if (class_addMethod(class_val, @selector(sel), (IMP)&$ ## class_name ## _ ## name ## _method, method_getTypeEncoding(method))) { \
				$ ## class_name ## _ ## name ## _super = &$ ## class_name ## _ ## name ## _closure; \
			} else { \
				method_setImplementation(method, (IMP)&$ ## class_name ## _ ## name ## _method); \
			} \
		} \
	} \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args)
#define CHMethod_self_(return_type, class_type, class_name, class_val, super_class_val, name, sel, sigdef, supercall, args...) \
	static return_type (*$ ## class_name ## _ ## name ## _super)(class_type self, SEL _cmd, ##args); \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args); \
	__attribute__((always_inline)) \
	static inline void $ ## class_name ## _ ## name ## _register() { \
		Method method = class_getInstanceMethod(class_val, @selector(sel)); \
		if (method) { \
			$ ## class_name ## _ ## name ## _super = (__typeof__($ ## class_name ## _ ## name ## _super))method_getImplementation(method); \
			method_setImplementation(method, (IMP)&$ ## class_name ## _ ## name ## _method); \
		} \
	} \
	static return_type $ ## class_name ## _ ## name ## _method(class_type self, SEL _cmd, ##args)
#endif
#define CHMethod(count, args...) \
	CHMethod ## count(args)
#define CHMethod0(return_type, class_type, name) \
	CHMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name, name, CHDeclareSig0_(return_type), (self, _cmd))
#define CHMethod1(return_type, class_type, name1, type1, arg1) \
	CHMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $, name1:, CHDeclareSig1_(return_type, type1), (self, _cmd, arg1), type1 arg1)
#define CHMethod2(return_type, class_type, name1, type1, arg1, name2, type2, arg2) \
	CHMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $, name1:name2:, CHDeclareSig2_(return_type, type1, type2), (self, _cmd, arg1, arg2), type1 arg1, type2 arg2)
#define CHMethod3(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3) \
	CHMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $, name1:name2:name3:, CHDeclareSig3_(return_type, type1, type2, type3), (self, _cmd, arg1, arg2, arg3), type1 arg1, type2 arg2, type3 arg3)
#define CHMethod4(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4) \
	CHMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $, name1:name2:name3:name4:, CHDeclareSig4_(return_type, type1, type2, type3, type4), (self, _cmd, arg1, arg2, arg3, arg4), type1 arg1, type2 arg2, type3 arg3, type4 arg4)
#define CHMethod5(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5) \
	CHMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $, name1:name2:name3:name4:name5:, CHDeclareSig5_(return_type, type1, type2, type3, type4, type5), (self, _cmd, arg1, arg2, arg3, arg4, arg5), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5)
#define CHMethod6(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6) \
	CHMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $, name1:name2:name3:name4:name5:name6:, CHDeclareSig6_(return_type, type1, type2, type3, type4, type5, type6), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6)
#define CHMethod7(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7) \
	CHMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $, name1:name2:name3:name4:name5:name6:name7:, CHDeclareSig7_(return_type, type1, type2, type3, type4, type5, type6, type7), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7)
#define CHMethod8(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7, name8, type8, arg8) \
	CHMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $, name1:name2:name3:name4:name5:name6:name7:name8:, CHDeclareSig8_(return_type, type1, type2, type3, type4, type5, type6, type7, type8), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7, type8 arg8)
#define CHMethod9(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7, name8, type8, arg8, name9, type9, arg9) \
	CHMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $ ## name9 ## $, name1:name2:name3:name4:name5:name6:name7:name8:name9:, CHDeclareSig9_(return_type, type1, type2, type3, type4, type5, type6, type7, type8, type9), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7, type8 arg8, type9 arg9)
#define CHClassMethod(count, args...) \
	CHClassMethod ## count(args)
#define CHClassMethod0(return_type, class_type, name) \
	CHMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name, name, CHDeclareSig0_(return_type), (self, _cmd))
#define CHClassMethod1(return_type, class_type, name1, type1, arg1) \
	CHMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $, name1:, CHDeclareSig1_(return_type, type1), (self, _cmd, arg1), type1 arg1)
#define CHClassMethod2(return_type, class_type, name1, type1, arg1, name2, type2, arg2) \
	CHMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $, name1:name2:, CHDeclareSig2_(return_type, type1, type2), (self, _cmd, arg1, arg2), type1 arg1, type2 arg2)
#define CHClassMethod3(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3) \
	CHMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $, name1:name2:name3:, CHDeclareSig3_(return_type, type1, type2, type3), (self, _cmd, arg1, arg2, arg3), type1 arg1, type2 arg2, type3 arg3)
#define CHClassMethod4(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4) \
	CHMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $, name1:name2:name3:name4:, CHDeclareSig4_(return_type, type1, type2, type3, type4), (self, _cmd, arg1, arg2, arg3, arg4), type1 arg1, type2 arg2, type3 arg3, type4 arg4)
#define CHClassMethod5(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5) \
	CHMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $, name1:name2:name3:name4:name5:, CHDeclareSig5_(return_type, type1, type2, type3, type4, type5), (self, _cmd, arg1, arg2, arg3, arg4, arg5), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5)
#define CHClassMethod6(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6) \
	CHMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $, name1:name2:name3:name4:name5:name6:, CHDeclareSig6_(return_type, type1, type2, type3, type4, type5, type6), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6)
#define CHClassMethod7(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7) \
	CHMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $, name1:name2:name3:name4:name5:name6:name7:, CHDeclareSig7_(return_type, type1, type2, type3, type4, type5, type6, type7), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7)
#define CHClassMethod8(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7, name8, type8, arg8) \
	CHMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $, name1:name2:name3:name4:name5:name6:name7:name8:, CHDeclareSig8_(return_type, type1, type2, type3, type4, type5, type6, type7, type8), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7, type8 arg8)
#define CHClassMethod9(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7, name8, type8, arg8, name9, type9, arg9) \
	CHMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $ ## name9 ## $, name1:name2:name3:name4:name5:name6:name7:name8:name9:, CHDeclareSig9_(return_type, type1, type2, type3, type4, type5, type6, type7, type8, type9), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7, type8 arg8, type9 arg9)
#define CHOptimizedMethod(count, args...) \
	CHOptimizedMethod ## count(args)
#define CHOptimizedMethod0(optimization, return_type, class_type, name) \
	CHMethod_ ## optimization ## _(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name, name, CHDeclareSig0_(return_type), (self, _cmd))
#define CHOptimizedMethod1(optimization, return_type, class_type, name1, type1, arg1) \
	CHMethod_ ## optimization ## _(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $, name1:, CHDeclareSig1_(return_type, type1), (self, _cmd, arg1), type1 arg1)
#define CHOptimizedMethod2(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2) \
	CHMethod_ ## optimization ## _(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $, name1:name2:, CHDeclareSig2_(return_type, type1, type2), (self, _cmd, arg1, arg2), type1 arg1, type2 arg2)
#define CHOptimizedMethod3(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3) \
	CHMethod_ ## optimization ## _(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $, name1:name2:name3:, CHDeclareSig3_(return_type, type1, type2, type3), (self, _cmd, arg1, arg2, arg3), type1 arg1, type2 arg2, type3 arg3)
#define CHOptimizedMethod4(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4) \
	CHMethod_ ## optimization ## _(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $, name1:name2:name3:name4:, CHDeclareSig4_(return_type, type1, type2, type3, type4), (self, _cmd, arg1, arg2, arg3, arg4), type1 arg1, type2 arg2, type3 arg3, type4 arg4)
#define CHOptimizedMethod5(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5) \
	CHMethod_ ## optimization ## _(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $, name1:name2:name3:name4:name5:, CHDeclareSig5_(return_type, type1, type2, type3, type4, type5), (self, _cmd, arg1, arg2, arg3, arg4, arg5), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5)
#define CHOptimizedMethod6(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6) \
	CHMethod_ ## optimization ## _(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $, name1:name2:name3:name4:name5:name6:, CHDeclareSig6_(return_type, type1, type2, type3, type4, type5, type6), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6)
#define CHOptimizedMethod7(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7) \
	CHMethod_ ## optimization ## _(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $, name1:name2:name3:name4:name5:name6:name7:, CHDeclareSig7_(return_type, type1, type2, type3, type4, type5, type6, type7), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7)
#define CHOptimizedMethod8(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7, name8, type8, arg8) \
	CHMethod_ ## optimization ## _(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $, name1:name2:name3:name4:name5:name6:name7:name8:, CHDeclareSig8_(return_type, type1, type2, type3, type4, type5, type6, type7, type8), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7, type8 arg8)
#define CHOptimizedMethod9(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7, name8, type8, arg8, name9, type9, arg9) \
	CHMethod_ ## optimization ## _(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $ ## name9 ## $, name1:name2:name3:name4:name5:name6:name7:name8:name9:, CHDeclareSig9_(return_type, type1, type2, type3, type4, type5, type6, type7, type8, type9), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7, type8 arg8, type9 arg9)
#define CHOptimizedClassMethod(count, args...) \
	CHOptimizedClassMethod ## count(args)
#define CHOptimizedClassMethod0(optimization, return_type, class_type, name) \
	CHMethod_ ## optimization ## _(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name, name, CHDeclareSig0_(return_type), (self, _cmd))
#define CHOptimizedClassMethod1(optimization, return_type, class_type, name1, type1, arg1) \
	CHMethod_ ## optimization ## _(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $, name1:, CHDeclareSig1_(return_type, type1), (self, _cmd, arg1), type1 arg1)
#define CHOptimizedClassMethod2(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2) \
	CHMethod_ ## optimization ## _(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $, name1:name2:, CHDeclareSig2_(return_type, type1, type2), (self, _cmd, arg1, arg2), type1 arg1, type2 arg2)
#define CHOptimizedClassMethod3(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3) \
	CHMethod_ ## optimization ## _(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $, name1:name2:name3:, CHDeclareSig3_(return_type, type1, type2, type3), (self, _cmd, arg1, arg2, arg3), type1 arg1, type2 arg2, type3 arg3)
#define CHOptimizedClassMethod4(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4) \
	CHMethod_ ## optimization ## _(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $, name1:name2:name3:name4:, CHDeclareSig4_(return_type, type1, type2, type3, type4), (self, _cmd, arg1, arg2, arg3, arg4), type1 arg1, type2 arg2, type3 arg3, type4 arg4)
#define CHOptimizedClassMethod5(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5) \
	CHMethod_ ## optimization ## _(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $, name1:name2:name3:name4:name5:, CHDeclareSig5_(return_type, type1, type2, type3, type4, type5), (self, _cmd, arg1, arg2, arg3, arg4, arg5), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5)
#define CHOptimizedClassMethod6(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6) \
	CHMethod_ ## optimization ## _(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $, name1:name2:name3:name4:name5:name6:, CHDeclareSig6_(return_type, type1, type2, type3, type4, type5, type6), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6)
#define CHOptimizedClassMethod7(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7) \
	CHMethod_ ## optimization ## _(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $, name1:name2:name3:name4:name5:name6:name7:, CHDeclareSig7_(return_type, type1, type2, type3, type4, type5, type6, type7), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7)
#define CHOptimizedClassMethod8(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7, name8, type8, arg8) \
	CHMethod_ ## optimization ## _(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $, name1:name2:name3:name4:name5:name6:name7:name8:, CHDeclareSig8_(return_type, type1, type2, type3, type4, type5, type6, type7, type8), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7, type8 arg8)
#define CHOptimizedClassMethod9(optimization, return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7, name8, type8, arg8, name9, type9, arg9) \
	CHMethod_ ## optimization ## _(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $ ## name9 ## $, name1:name2:name3:name4:name5:name6:name7:name8:name9:, CHDeclareSig9_(return_type, type1, type2, type3, type4, type5, type6, type7, type8, type9), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7, type8 arg8, type9 arg9)

// Replacement Method Registration
#define CHHook_(class_name, name) \
	$ ## class_name ## _ ## name ## _register()
#define CHHook(count, args...) CHHook ## count(args)
#define CHHook0(class, name) CHHook_(class, name)
#define CHHook1(class, name1) CHHook_(class, name1 ## $)
#define CHHook2(class, name1, name2) CHHook_(class, name1 ## $ ## name2 ## $)
#define CHHook3(class, name1, name2, name3) CHHook_(class, name1 ## $ ## name2 ## $ ## name3 ## $)
#define CHHook4(class, name1, name2, name3, name4) CHHook_(class, name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $)
#define CHHook5(class, name1, name2, name3, name4, name5) CHHook_(class, name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $)
#define CHHook6(class, name1, name2, name3, name4, name5, name6) CHHook_(class, name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $)
#define CHHook7(class, name1, name2, name3, name4, name5, name6, name7) CHHook_(class, name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $)
#define CHHook8(class, name1, name2, name3, name4, name5, name6, name7, name8) CHHook_(class, name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $)
#define CHHook9(class, name1, name2, name3, name4, name5, name6, name7, name8, name9) CHHook_(class, name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $ ## name9 ## $)
#define CHClassHook(count, args...) CHClassHook ## count(args)
#define CHClassHook0(class, name) CHHook_(class, name)
#define CHClassHook1(class, name1) CHHook_(class, name1 ## $)
#define CHClassHook2(class, name1, name2) CHHook_(class, name1 ## $ ## name2 ## $)
#define CHClassHook3(class, name1, name2, name3) CHHook_(class, name1 ## $ ## name2 ## $ ## name3 ## $)
#define CHClassHook4(class, name1, name2, name3, name4) CHHook_(class, name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $)
#define CHClassHook5(class, name1, name2, name3, name4, name5) CHHook_(class, name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $)
#define CHClassHook6(class, name1, name2, name3, name4, name5, name6) CHHook_(class, name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $)
#define CHClassHook7(class, name1, name2, name3, name4, name5, name6, name7) CHHook_(class, name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $)
#define CHClassHook8(class, name1, name2, name3, name4, name5, name6, name7, name8) CHHook_(class, name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $)
#define CHClassHook9(class, name1, name2, name3, name4, name5, name6, name7, name8, name9) CHHook_(class, name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $ ## name9 ## $)

// Declarative style methods (automatically calls CHHook)
#define CHDeclareMethod_(return_type, class_type, class_name, class_val, super_class_val, name, sel, sigdef, supercall, args...) \
	static inline void $ ## class_name ## _ ## name ## _register(); \
	__attribute__((constructor)) \
	static inline void $ ## class_name ## _ ## name ## _constructor() { \
		CHLoadLateClass(class_name); \
		$ ## class_name ## _ ## name ## _register(); \
	} \
	CHMethod_(return_type, class_type, class_name, class_val, super_class_val, name, sel, sigdef, supercall, ##args)
#define CHDeclareMethod(count, args...) \
	CHDeclareMethod ## count(args)
#define CHDeclareMethod0(return_type, class_type, name) \
	CHDeclareMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name, name, CHDeclareSig0_(return_type), (self, _cmd))
#define CHDeclareMethod1(return_type, class_type, name1, type1, arg1) \
	CHDeclareMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $, name1:, CHDeclareSig1_(return_type, type1), (self, _cmd, arg1), type1 arg1)
#define CHDeclareMethod2(return_type, class_type, name1, type1, arg1, name2, type2, arg2) \
	CHDeclareMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $, name1:name2:, CHDeclareSig2_(return_type, type1, type2), (self, _cmd, arg1, arg2), type1 arg1, type2 arg2)
#define CHDeclareMethod3(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3) \
	CHDeclareMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $, name1:name2:name3:, CHDeclareSig3_(return_type, type1, type2, type3), (self, _cmd, arg1, arg2, arg3), type1 arg1, type2 arg2, type3 arg3)
#define CHDeclareMethod4(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4) \
	CHDeclareMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $, name1:name2:name3:name4:, CHDeclareSig4_(return_type, type1, type2, type3, type4), (self, _cmd, arg1, arg2, arg3, arg4), type1 arg1, type2 arg2, type3 arg3, type4 arg4)
#define CHDeclareMethod5(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5) \
	CHDeclareMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## arg5 ## $, name1:name2:name3:name4:name5:, CHDeclareSig5_(return_type, type1, type2, type3, type4, type5), (self, _cmd, arg1, arg2, arg3, arg4, arg5), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5)
#define CHDeclareMethod6(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6) \
	CHDeclareMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $, name1:name2:name3:name4:name5:name6:, CHDeclareSig6_(return_type, type1, type2, type3, type4, type5, type6), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6)
#define CHDeclareMethod7(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7) \
	CHDeclareMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $, name1:name2:name3:name4:name5:name6:name7:, CHDeclareSig7_(return_type, type1, type2, type3, type4, type5, type6, type7), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7)
#define CHDeclareMethod8(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7, name8, type8, arg8) \
	CHDeclareMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $, name1:name2:name3:name4:name5:name6:name7:name8:, CHDeclareSig8_(return_type, type1, type2, type3, type4, type5, type6, type7, type8), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7, type8 arg8)
#define CHDeclareMethod9(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7, name8, type8, arg8, name9, type9, arg9) \
	CHDeclareMethod_(return_type, class_type *, class_type, CHClass(class_type), CHSuperClass(class_type), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $ ## name9 ## $, name1:name2:name3:name4:name5:name6:name7:name8:name9:, CHDeclareSig9_(return_type, type1, type2, type3, type4, type5, type6, type7, type8, type9), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7, type8 arg8, type9 arg9)
#define CHDeclareClassMethod(count, args...) \
	CHDeclareClassMethod ## count(args)
#define CHDeclareClassMethod0(return_type, class_type, name) \
	CHDeclareMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name, name, CHDeclareSig0_(return_type), (self, _cmd))
#define CHDeclareClassMethod1(return_type, class_type, name1, type1, arg1) \
	CHDeclareMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $, name1:, CHDeclareSig1_(return_type, type1), (self, _cmd, arg1), type1 arg1)
#define CHDeclareClassMethod2(return_type, class_type, name1, type1, arg1, name2, type2, arg2) \
	CHDeclareMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $, name1:name2:, CHDeclareSig2_(return_type, type1, type2), (self, _cmd, arg1, arg2), type1 arg1, type2 arg2)
#define CHDeclareClassMethod3(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3) \
	CHDeclareMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $, name1:name2:name3:, CHDeclareSig3_(return_type, type1, type2, type3), (self, _cmd, arg1, arg2, arg3), type1 arg1, type2 arg2, type3 arg3)
#define CHDeclareClassMethod4(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4) \
	CHDeclareMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $, name1:name2:name3:name4:, CHDeclareSig4_(return_type, type1, type2, type3, type4), (self, _cmd, arg1, arg2, arg3, arg4), type1 arg1, type2 arg2, type3 arg3, type4 arg4)
#define CHDeclareClassMethod5(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5) \
	CHDeclareMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $, name1:name2:name3:name4:name5:, CHDeclareSig5_(return_type, type1, type2, type3, type4, type5), (self, _cmd, arg1, arg2, arg3, arg4, arg5), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5)
#define CHDeclareClassMethod6(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6) \
	CHDeclareMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $, name1:name2:name3:name4:name5:name6:, CHDeclareSig6_(return_type, type1, type2, type3, type4, type5, type6), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6)
#define CHDeclareClassMethod7(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7) \
	CHDeclareMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $, name1:name2:name3:name4:name5:name6:name7:, CHDeclareSig7_(return_type, type1, type2, type3, type4, type5, type6, type7), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7)
#define CHDeclareClassMethod8(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7, name8, type8, arg8) \
	CHDeclareMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $, name1:name2:name3:name4:name5:name6:name7:name8:, CHDeclareSig8_(return_type, type1, type2, type3, type4, type5, type6, type7, type8), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7, type8 arg8)
#define CHDeclareClassMethod9(return_type, class_type, name1, type1, arg1, name2, type2, arg2, name3, type3, arg3, name4, type4, arg4, name5, type5, arg5, name6, type6, arg6, name7, type7, arg7, name8, type8, arg8, name9, type9, arg9) \
	CHDeclareMethod_(return_type, id, class_type, CHMetaClass(class_type), object_getClass(CHMetaClass(class_type)), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $ ## name9 ## $, name1:name2:name3:name4:name5:name6:name7:name8:name9:, CHDeclareSig9_(return_type, type1, type2, type3, type4, type5, type6, type7, type8, type9), (self, _cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9), type1 arg1, type2 arg2, type3 arg3, type4 arg4, type5 arg5, type6 arg6, type7 arg7, type8 arg8, type9 arg9)

// Calling super class (or the old method as the case may be)
#define CHSuper_(class_type, _cmd, name, args...) \
	$ ## class_type ## _ ## name ## _super(self, _cmd, ##args)
#define CHSuper(count, args...) \
	CHSuper ## count(args)
#define CHSuper0(class_type, name) \
	CHSuper_(class_type, @selector(name), name)
#define CHSuper1(class_type, name1, val1) \
	CHSuper_(class_type, @selector(name1:), name1 ## $, val1)
#define CHSuper2(class_type, name1, val1, name2, val2) \
	CHSuper_(class_type, @selector(name1:name2:), name1 ## $ ## name2 ## $, val1, val2)
#define CHSuper3(class_type, name1, val1, name2, val2, name3, val3) \
	CHSuper_(class_type, @selector(name1:name2:name3:), name1 ## $ ## name2 ## $ ## name3 ## $, val1, val2, val3)
#define CHSuper4(class_type, name1, val1, name2, val2, name3, val3, name4, val4) \
	CHSuper_(class_type, @selector(name1:name2:name3:name4:), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $, val1, val2, val3, val4)
#define CHSuper5(class_type, name1, val1, name2, val2, name3, val3, name4, val4, name5, val5) \
	CHSuper_(class_type, @selector(name1:name2:name3:name4:name5:), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $, val1, val2, val3, val4, val5)
#define CHSuper6(class_type, name1, val1, name2, val2, name3, val3, name4, val4, name5, val5, name6, val6) \
	CHSuper_(class_type, @selector(name1:name2:name3:name4:name5:name6:), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $, val1, val2, val3, val4, val5, val6)
#define CHSuper7(class_type, name1, val1, name2, val2, name3, val3, name4, val4, name5, val5, name6, val6, name7, val7) \
	CHSuper_(class_type, @selector(name1:name2:name3:name4:name5:name6:name7:), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $, val1, val2, val3, val4, val5, val6, val7)
#define CHSuper8(class_type, name1, val1, name2, val2, name3, val3, name4, val4, name5, val5, name6, val6, name7, val7, name8, val8) \
	CHSuper_(class_type, @selector(name1:name2:name3:name4:name5:name6:name7:name8:), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $, val1, val2, val3, val4, val5, val6, val7, val8)
#define CHSuper9(class_type, name1, val1, name2, val2, name3, val3, name4, val4, name5, val5, name6, val6, name7, val7, name8, val8, name9, val9) \
	CHSuper_(class_type, @selector(name1:name2:name3:name4:name5:name6:name7:name8:name9:), name1 ## $ ## name2 ## $ ## name3 ## $ ## name4 ## $ ## name5 ## $ ## name6 ## $ ## name7 ## $ ## name8 ## $ ## name9 ## $, val1, val2, val3, val4, val5, val6, val7, val8, val9)

// Create Class at Runtime (useful for creating subclasses of classes that can't be linked)
#define CHRegisterClass(name, superName) for (int _tmp = ({ CHClass(name) = objc_allocateClassPair(CHClass(superName), #name, 0); CHMetaClass(name) = object_getClass(CHClass(name)); CHSuperClass(name) = class_getSuperclass(CHClass(name)); 1; }); _tmp; _tmp = ({ objc_registerClassPair(CHClass(name)), 0; }))
#define CHAlignmentForSize_(size) ({ \
	size_t s = size; \
	__builtin_constant_p(s) ? ( \
		(s) & (1 << 31) ? 31 : \
		(s) & (1 << 30) ? 30 : \
		(s) & (1 << 29) ? 29 : \
		(s) & (1 << 28) ? 28 : \
		(s) & (1 << 27) ? 27 : \
		(s) & (1 << 26) ? 26 : \
		(s) & (1 << 25) ? 25 : \
		(s) & (1 << 24) ? 24 : \
		(s) & (1 << 23) ? 23 : \
		(s) & (1 << 22) ? 22 : \
		(s) & (1 << 21) ? 21 : \
		(s) & (1 << 20) ? 20 : \
		(s) & (1 << 19) ? 19 : \
		(s) & (1 << 18) ? 18 : \
		(s) & (1 << 17) ? 17 : \
		(s) & (1 << 16) ? 16 : \
		(s) & (1 << 15) ? 15 : \
		(s) & (1 << 14) ? 14 : \
		(s) & (1 << 13) ? 13 : \
		(s) & (1 << 12) ? 12 : \
		(s) & (1 << 11) ? 11 : \
		(s) & (1 << 10) ? 10 : \
		(s) & (1 <<  9) ?  9 : \
		(s) & (1 <<  8) ?  8 : \
		(s) & (1 <<  7) ?  7 : \
		(s) & (1 <<  6) ?  6 : \
		(s) & (1 <<  5) ?  5 : \
		(s) & (1 <<  4) ?  4 : \
		(s) & (1 <<  3) ?  3 : \
		(s) & (1 <<  2) ?  2 : \
		(s) & (1 <<  1) ?  1 : \
		(s) & (1 <<  0) ?  0 : \
		0 \
	) : (uint32_t)log2f(s); \
})
#define CHAddIvar(targetClass, name, type) \
	class_addIvar(targetClass, #name, sizeof(type), CHAlignmentForSize_(sizeof(type)), @encode(type))

// Retrieve reference to an Ivar value (can read and assign)
__attribute__((unused)) CHInline
static void *CHIvar_(id object, const char *name)
{
	Ivar ivar = class_getInstanceVariable(object_getClass(object), name);
	if (ivar)
#ifdef CHHasARC
		return (void *)&((char *)(__bridge void *)object)[ivar_getOffset(ivar)];
#else
		return (void *)&((char *)object)[ivar_getOffset(ivar)];
#endif
	return NULL;
}
#define CHIvarRef(object, name, type) \
	((type *)CHIvar_(object, #name))
#define CHIvar(object, name, type) \
	(*CHIvarRef(object, name, type))
	// Warning: Dereferences NULL if object is nil or name isn't found. To avoid this save CHIvarRef(...) and test if != NULL

#define CHDeclareProperty(class, name) static const char k ## class ## _ ## name;
#define CHPropertyGetValue(class, name) objc_getAssociatedObject(self, &k ## class ## _ ## name )
#define CHPropertySetValue(class, name, value, policy) objc_setAssociatedObject(self, &k ## class ## _ ## name , value, policy)

#define CHPropertyGetter(class, getter, type) CHOptimizedMethod0(new, type, class, getter)
#define CHPropertySetter(class, setter, type, value) CHOptimizedMethod1(new, void, class, setter, type, value)

// Obj-C dynamic property declaration (objects)
#define CHProperty(class, type, getter, setter, policy) \
	CHDeclareProperty(class, getter) \
	CHPropertyGetter(class, getter, type) { \
		return CHPropertyGetValue(class, getter); \
	} \
	CHPropertySetter(class, setter, type, getter) { \
		CHPropertySetValue(class, getter, getter, policy); \
	}
#define CHPropertyRetain(class, type, getter, setter) CHProperty(class, type, getter, setter, OBJC_ASSOCIATION_RETAIN)
#define CHPropertyRetainNonatomic(class, type, getter, setter) CHProperty(class, type, getter, setter, OBJC_ASSOCIATION_RETAIN_NONATOMIC)
#define CHPropertyCopy(class, type, getter, setter) CHProperty(class, type, getter, setter, OBJC_ASSOCIATION_COPY)
#define CHPropertyCopyNonatomic(class, type, getter, setter) CHProperty(class, type, getter, setter, OBJC_ASSOCIATION_COPY_NONATOMIC)
#define CHPropertyAssign(class, type, getter, setter) CHProperty(class, type, getter, setter, OBJC_ASSOCIATION_ASSIGN)

#define CHPrimitivePropertyGetValue(class, name, type, val, default) \
	type val = default; \
	do { \
		NSNumber * objVal = CHPropertyGetValue(class, name); \
		[objVal getValue:& val ]; \
	} while(0)
#define CHPrimitivePropertySetValue(class, name, type, val) \
	do { \
		NSValue *objVal = [NSValue value:& val withObjCType:@encode( type )]; \
		CHPropertySetValue(class, name, objVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC); \
	} while(0)

// Primitive property equivalent (ie. BOOL, int, structs)
#define CHPrimitiveProperty(class, type, getter, setter, default) \
	CHDeclareProperty(class, getter) \
	CHOptimizedMethod0(new, type, class, getter) { \
		CHPrimitivePropertyGetValue( class , getter , type , val , default ); \
		return val; \
	} \
	CHOptimizedMethod1(new, void, class, setter, type, getter) { \
		CHPrimitivePropertySetValue( class , getter, type , getter ); \
	}

#define CHHookProperty(class, getter, setter) \
	do { \
		CHHook0(class, getter); \
		CHHook1(class, setter); \
	} while(0)

#ifndef CHHasARC
// Scope Autorelease
__attribute__((unused)) CHInline
static void CHScopeReleased(id *sro)
{
    [*sro release];
}
#define CHScopeReleased \
	__attribute__((cleanup(CHScopeReleased)))

#define CHAutoreleasePoolForScope() \
	NSAutoreleasePool *CHAutoreleasePoolForScope __attribute__((unused)) CHScopeReleased = [[NSAutoreleasePool alloc] init]
#endif

// Build Assertion
#define CHBuildAssert(condition) \
	((void)sizeof(char[1 - 2*!!(condition)]))

// Profiling
#ifdef CHEnableProfiling
	#import <mach/mach_time.h>
	struct CHProfileData
	{
		NSString *message;
		uint64_t startTime;
	};
	__attribute__((unused)) CHInline
	static void CHProfileCalculateDurationAndLog_(struct CHProfileData *profileData)
	{
		uint64_t duration = mach_absolute_time() - profileData->startTime;
		mach_timebase_info_data_t info;
		mach_timebase_info(&info);
		duration = (duration * info.numer) / info.denom;
		CHLog(@"Profile time: %lldns; %@", duration, profileData->message);
	}
	#define CHProfileScopeWithString(string) \
		struct CHProfileData _profileData __attribute__((cleanup(CHProfileCalculateDurationAndLog_))) = ({ struct CHProfileData _tmp; _tmp.message = (string); _tmp.startTime = mach_absolute_time(); _tmp; })
#else
	#define CHProfileScopeWithString(string) \
		CHNothing()
#endif
#define CHProfileScopeWithFormat(args...) \
	CHProfileScopeWithString(([NSString stringWithFormat:args]))
#define CHProfileScope() \
	CHProfileScopeWithFormat(@CHStringify(__LINE__) " in %s", __FUNCTION__)
