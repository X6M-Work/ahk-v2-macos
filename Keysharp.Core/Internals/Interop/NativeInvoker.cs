using Keysharp.Builtins;

namespace Keysharp.Internals.Interop
{
	/// <summary>
	/// ABI slot widths used when a platform ABI (notably Darwin ARM64) packs spilled stack parameters tighter than 8 bytes.
	/// </summary>
	internal enum NativeSlotKind : byte
	{
		I64 = 0,
		I32 = 1,
		U32 = 2,
		I16 = 3,
		U16 = 4,
		I8 = 5,
		U8 = 6,
		F32 = 7,
		F64 = 8
	}

	/// <summary>
	/// A generated native call: the function pointer plus the argument slots it reads, which live in the
	/// caller's stack frame. The two forms differ only in which register the return value comes back in.
	/// </summary>
	internal unsafe delegate long NativeCall(nint fn, long* args);
	internal unsafe delegate double NativeCallFloat(nint fn, long* args);
	internal unsafe delegate float NativeCallFloat32(nint fn, long* args);

	internal class DllData
	{
		// These caches are unbounded in principle but small in practice: delegateCache is keyed by the call's
		// shape (argument count plus which slots are floating point), of which a script uses a handful, and
		// procAddressCache by the function strings it writes.
		internal readonly ConcurrentDictionary<ulong, Delegate> delegateCache = new ();
		// Signatures with more than 57 arguments, whose float mask does not fit alongside the count in the
		// packed key above. Vanishingly rare, so a tuple key costs nothing worth measuring.
		internal readonly ConcurrentDictionary<(int, ulong), Delegate> wideDelegateCache = new ();
		// Exact-width invokers keyed by slot-kind string, used only when >8 args spill narrow/float values on Darwin ARM64.
		internal readonly ConcurrentDictionary<string, Delegate> exactDelegateCache = new (StringComparer.Ordinal);
		// The signature nearly every call has -- every argument and the return value an integer -- is indexed by
		// argument count alone, so the common case is an array read rather than a hash lookup.
		internal readonly Delegate[] integerInvokers = new Delegate[NativeInvoker.MaxArguments + 1];
		// Ordinal, matching the case-sensitive GetProcAddress/dlsym this memoises: a differently spelled function
		// name does not resolve there either, so an ignore-case cache would only paper over the failure for
		// whichever spelling happened to be looked up first, at the cost of a slower hash on every call.
		internal readonly ConcurrentDictionary<string, nint> procAddressCache = new (StringComparer.Ordinal);
#if WINDOWS
		// x64 register-duplication shims, one per (function, floating-point argument pattern); see Dll.GetShim.
		internal readonly ConcurrentDictionary<(nint, int), nint> shimCache = new ();
		internal readonly Lock shimLock = new ();
#endif
	}

	/// <summary>
	/// Generates and caches the machine code that actually performs a native call: one invoker per call
	/// signature, plus the x64 shim that duplicates floating point arguments into general purpose registers.
	/// <para>Kept apart from <see cref="Keysharp.Builtins.Dll"/>, which is the script-facing built-in: this
	/// half speaks only the platform ABI and knows nothing about script values.</para>
	/// </summary>
	internal static class NativeInvoker
	{
		/// <summary>
		/// The most arguments one call may take. The generated-invoker cache key packs the argument count into
		/// the top six bits of a 64-bit word, so a longer list would collide with another signature's entry;
		/// it also bounds the stack space each call reserves for its argument slots.
		/// </summary>
		internal const int MaxArguments = 63;

		internal static readonly bool IsDarwinArm64 = OperatingSystem.IsMacOS() && RuntimeInformation.ProcessArchitecture == Architecture.Arm64;

		internal static NativeSlotKind MapSlotKind(NativeTypeCode code, bool byAddress) => byAddress ? NativeSlotKind.I64 : code switch
		{
			NativeTypeCode.Char => NativeSlotKind.I8,
			NativeTypeCode.UChar => NativeSlotKind.U8,
			NativeTypeCode.Short => NativeSlotKind.I16,
			NativeTypeCode.UShort => NativeSlotKind.U16,
			NativeTypeCode.Int or NativeTypeCode.HResult => NativeSlotKind.I32,
			NativeTypeCode.UInt => NativeSlotKind.U32,
			NativeTypeCode.Float => NativeSlotKind.F32,
			NativeTypeCode.Double => NativeSlotKind.F64,
			_ => NativeSlotKind.I64
		};

		internal static bool RequiresExactDarwinArm64Signature(ReadOnlySpan<NativeSlotKind> argKinds)
		{
			if (argKinds.Length <= 8)
				return false;

			var gprCount = 0;
			var fprCount = 0;

			foreach (var kind in argKinds)
			{
				if (kind is NativeSlotKind.F32 or NativeSlotKind.F64)
				{
					if (fprCount >= 8 && kind == NativeSlotKind.F32)
						return true;

					fprCount++;
				}
				else
				{
					if (gprCount >= 8 && kind != NativeSlotKind.I64)
						return true;

					gprCount++;
				}
			}

			return false;
		}

		internal static string BuildExactSignatureKey(ReadOnlySpan<NativeSlotKind> argKinds, NativeSlotKind returnKind)
		{
			Span<char> chars = stackalloc char[argKinds.Length + 1];

			for (var i = 0; i < argKinds.Length; i++)
				chars[i] = (char)('0' + (int)argKinds[i]);

			chars[argKinds.Length] = (char)('0' + (int)returnKind);
			return new string(chars);
		}

		internal static unsafe long NativeInvokeExact(nint fnPtr, Span<long> args, ReadOnlySpan<NativeSlotKind> argKinds, NativeSlotKind returnKind)
		{
			int n = args.Length;

			if ((uint)n > MaxArguments)
				return (long)Errors.ValueErrorOccurred($"A native call cannot take more than {MaxArguments} arguments.", ret: 0L);

			if (argKinds.Length != n)
				return (long)Errors.ValueErrorOccurred($"Argument slot kinds length ({argKinds.Length}) does not match argument count ({n}).", ret: 0L);

			var dllData = TheScript.DllData;
			var key = BuildExactSignatureKey(argKinds, returnKind);

			if (!dllData.exactDelegateCache.TryGetValue(key, out var del))
			{
				var kindsCopy = argKinds.ToArray();
				del = dllData.exactDelegateCache.GetOrAdd(key, static (_, state) => CreateExactInvoker(state.kindsCopy, state.returnKind), (kindsCopy, returnKind));
			}

			long result;

			fixed (long* p = args)
			{
				result = returnKind switch
				{
					NativeSlotKind.F32 => BitConverter.SingleToInt32Bits(((NativeCallFloat32)del)(fnPtr, p)),
					NativeSlotKind.F64 => BitConverter.DoubleToInt64Bits(((NativeCallFloat)del)(fnPtr, p)),
					_ => ((NativeCall)del)(fnPtr, p)
				};
			}

			ThreadAccessors.A_LastError = Marshal.GetLastSystemError();
			return result;
		}

		/// <summary>
		/// Performs the call, compiling and caching an invoker for its signature the first time that signature
		/// is seen. Every argument slot is a <see cref="long"/> here; the mask says which ones the callee reads
		/// as floating point.
		/// </summary>
		/// <param name="fnPtr">The pointer to the native function to be called.</param>
		/// <param name="args">The argument list, which the call may write back through.</param>
		/// <param name="mask">64-bit mask containing information about floating point arguments and return value</param>
		/// <returns>The raw contents of the return register; a floating-point return arrives as its bits.</returns>
		internal static unsafe long NativeInvoke(nint fnPtr, Span<long> args, ulong mask)
		{
			int n = args.Length;

			//The callers check this before allocating their argument slots; re-checked here so that a future
			//caller which forgets gets a script-level error rather than an IndexOutOfRangeException out of the
			//invoker cache below.
			if ((uint)n > MaxArguments)
				return (long)Errors.ValueErrorOccurred($"A native call cannot take more than {MaxArguments} arguments.", ret: 0L);

			var dllData = TheScript.DllData;
			Delegate del;

			if (mask == 0)
				del = dllData.integerInvokers[n] ??= CreateInvoker(n, 0);
			else if (n > 57)
				//The packed key below cannot carry mask bits this high, so these signatures get their own cache
				//rather than colliding. Rare enough to be worth a tuple key, but not worth re-JITting per call.
				del = dllData.wideDelegateCache.GetOrAdd((n, mask), static k => CreateInvoker(k.Item1, k.Item2));
			else
			{
				// pack n into bits 58–63, mask occupies bits 0–57
				ulong key = ((ulong)n << 58) | mask;

				// TryGetValue first: GetOrAdd's factory would capture n and mask into a fresh closure on every
				// call, including the common one where the delegate is already there.
				if (!dllData.delegateCache.TryGetValue(key, out del))
					del = dllData.delegateCache.GetOrAdd(key, static (_, state) => CreateInvoker(state.n, state.mask), (n, mask));
			}

#if WINDOWS

			// Under Windows x64 AutoHotkey passes the first four arguments in both general purpose and floating
			// point registers, so that a variadic callee, which reads them from the GPRs, sees them too. The
			// call is routed through a small shim which copies each such XMM into its GPR and jumps on.
			//
			// There is deliberately no ARM64 equivalent. AAPCS64 counts general and floating point argument
			// registers separately, so a value cannot occupy x_n and v_n at once the way it can occupy a GPR
			// and an XMM on x64 - duplicating it would consume an integer slot the next argument needs. A
			// non-variadic callee reads a double from v_n (which CreateInvoker's `double` parameter already
			// satisfies), while a Windows ARM64 variadic callee reads it from x_n, and DllCall has no way to
			// know which it is calling. Non-variadic calls are therefore correct and variadic calls with
			// floating point arguments are not; distinguishing them needs an explicit caller-supplied flag.
			if (isX64 && (mask & 0xFUL) != 0)
			{
				// Only argument slots count; a return bit inside the low four is not an argument.
				var pattern = (int)(mask & 0xFUL);

				if (n < 4)
					pattern &= ~(1 << n);

				if (pattern != 0)
					fnPtr = GetShim(dllData, fnPtr, pattern);
			}

#endif
			long result;

			// invoke with the correct delegate type
			fixed (long* p = args)
			{
				result = ((mask >> n) & 1) != 0
						 ? BitConverter.DoubleToInt64Bits(((NativeCallFloat)del)(fnPtr, p))
						 : ((NativeCall)del)(fnPtr, p);
			}

			ThreadAccessors.A_LastError = Marshal.GetLastSystemError();
			return result;
		}

#if WINDOWS
		private static readonly bool isX64 = RuntimeInformation.ProcessArchitecture == Architecture.X64;

		/// <summary>
		/// The most bytes <see cref="GetShim"/> can emit: four 5-byte MOVQs, a 6-byte JMP and an 8-byte address.
		/// </summary>
		private const int MaxShimBytes = (4 * 5) + 6 + 8;

		/// <summary>
		/// Fails to compile if a shim could ever overrun the chunk it is written into, since the two constants
		/// live in different files and the chunk next door holds another shim someone is about to jump to.
		/// </summary>
		private const uint ShimFitsChunk = ExecutableMemoryPoolManager.ChunkSize - MaxShimBytes;

		/// <summary>
		/// The shim for calling <paramref name="fnPtr"/> with the floating point arguments named by
		/// <paramref name="pattern"/> (a bit per slot 0-3) also in their general purpose registers.
		/// <para>Shims are built once and kept for the life of the script. Writing one into a chunk that was
		/// just executed, which a rent/return pair around every call amounts to, trips the processor's
		/// self-modifying-code detection and costs a pipeline flush per call, about 1.5 microseconds; a cached
		/// shim is written once and only ever executed afterwards.</para>
		/// </summary>
		private static unsafe nint GetShim(DllData dllData, nint fnPtr, int pattern)
		{
			var key = (fnPtr, pattern);

			if (dllData.shimCache.TryGetValue(key, out var shim))
				return shim;

			lock (dllData.shimLock)
			{
				if (dllData.shimCache.TryGetValue(key, out shim))
					return shim;

				shim = TheScript.ExecutableMemoryPoolManager.Rent();
				byte* ptr = (byte*)shim;

				// Emit MOVQ rcx←xmm0, rdx←xmm1, r8←xmm2, r9←xmm3 as needed. MOVQ from an XMM register to a
				// 64-bit GPR is `66 REX.W 0F 7E /r`: the 0x66 prefix and REX.W are both required, since
				// without REX.W the same opcode is MOVD and copies only the low 32 bits, and without the
				// 0x66 prefix it is the MMX MOVQ instead. ModRM is mod=11, reg=the XMM, rm=the GPR, with
				// REX.B extending rm to reach r8/r9.
				for (int i = 0; i < 4; i++)
				{
					if ((pattern & (1 << i)) == 0) continue;

					// rcx, rdx, r8, r9 as the low 3 bits of rm, the last two needing REX.B.
					const string rm = "\x01\x02\x00\x01";
					*ptr++ = 0x66;
					*ptr++ = (byte)(i < 2 ? 0x48 : 0x49);
					*ptr++ = 0x0F;
					*ptr++ = 0x7E;
					*ptr++ = (byte)(0xC0 | (i << 3) | rm[i]);
				}

				// Emit: JMP [RIP + 0]  => FF 25 00 00 00 00
				*ptr++ = 0xFF;* ptr++ = 0x25;* ptr++ = 0x00;* ptr++ = 0x00;* ptr++ = 0x00;* ptr++ = 0x00;

				// Followed immediately by the 64-bit absolute address
				*((long*)ptr) = fnPtr;
				System.Diagnostics.Debug.Assert(ptr + sizeof(long) - (byte*)shim <= ExecutableMemoryPoolManager.ChunkSize);
				dllData.shimCache[key] = shim;
				return shim;
			}
		}
#endif

#if WINDOWS
		/// <summary>
		/// Drops every cached shim for <paramref name="fnPtr"/> and gives the executable chunks back. Only for a
		/// function pointer that is about to become invalid: an ordinary library export keeps its shim, which is
		/// the whole point of caching them.
		/// </summary>
		internal static void ReleaseShims(nint fnPtr)
		{
			if (fnPtr == 0)
				return;

			var dllData = TheScript.DllData;

			//The pattern is only four bits wide, so naming every key is cheaper than scanning the dictionary.
			for (var pattern = 1; pattern < 16; pattern++)
				if (dllData.shimCache.TryRemove((fnPtr, pattern), out var shim))
					TheScript.ExecutableMemoryPoolManager.Return(shim);
		}
#endif

		/// <summary>
		/// Generates (and returns) a <see cref="NativeCall"/> or <see cref="NativeCallFloat"/> for a function
		/// pointer that accepts exactly n arguments. It reads each argument out of the slot array as either a
		/// long or a double, then loads the function pointer and calls it.
		/// <para>The slots arrive as a raw pointer rather than a long[] so that the caller can hand over stack
		/// space: an argument list allocated per call would be pure garbage, since nothing outlives the call.</para>
		/// </summary>
		/// <param name="n">The number of argument slots expected.</param>
		/// <param name="mask">Bitmask containing info about possible floating point number argument positions</param>
		private static unsafe Delegate CreateInvoker(int n, ulong mask)
		{
			var floatReturn = ((mask >> n) & 1) != 0;
			var returnType = floatReturn ? typeof(double) : typeof(long);
			var delegateType = floatReturn ? typeof(NativeCallFloat) : typeof(NativeCall);
			return CreateInvokerCore($"NativeCall_{n}_{mask}", n, returnType, delegateType, i => ((mask >> i) & 1) != 0 ? NativeSlotKind.F64 : NativeSlotKind.I64);
		}

		private static unsafe Delegate CreateExactInvoker(NativeSlotKind[] argKinds, NativeSlotKind returnKind)
		{
			var (returnType, delegateType) = returnKind switch
			{
				NativeSlotKind.F32 => (typeof(float), typeof(NativeCallFloat32)),
				NativeSlotKind.F64 => (typeof(double), typeof(NativeCallFloat)),
				_ => (typeof(long), typeof(NativeCall))
			};
			return CreateInvokerCore($"NativeCallExact_{BuildExactSignatureKey(argKinds, returnKind)}", argKinds.Length, returnType, delegateType, i => argKinds[i]);
		}

		private static unsafe Delegate CreateInvokerCore(string name, int n, Type returnType, Type delegateType, Func<int, NativeSlotKind> getSlotKind)
		{
			var dm = new DynamicMethod(
				name,
				returnType,
				[typeof(nint), typeof(long*)],
				typeof(Dll).Module,
				skipVisibility: true);
			var il = dm.GetILGenerator();
			var paramTypes = new Type[n];

			// 1) load each argument slot at its ABI width
			for (int i = 0; i < n; i++)
			{
				il.Emit(OpCodes.Ldarg_1);           // args

				if (i != 0)
				{
					il.Emit(OpCodes.Ldc_I4, i * sizeof(long));
					il.Emit(OpCodes.Add);
				}

				var (loadOp, paramType) = getSlotKind(i) switch
				{
					NativeSlotKind.I32 => (OpCodes.Ldind_I4, typeof(int)),
					NativeSlotKind.U32 => (OpCodes.Ldind_U4, typeof(uint)),
					NativeSlotKind.I16 => (OpCodes.Ldind_I2, typeof(short)),
					NativeSlotKind.U16 => (OpCodes.Ldind_U2, typeof(ushort)),
					NativeSlotKind.I8 => (OpCodes.Ldind_I1, typeof(sbyte)),
					NativeSlotKind.U8 => (OpCodes.Ldind_U1, typeof(byte)),
					NativeSlotKind.F32 => (OpCodes.Ldind_R4, typeof(float)),
					NativeSlotKind.F64 => (OpCodes.Ldind_R8, typeof(double)),
					_ => (OpCodes.Ldind_I8, typeof(long))
				};
				il.Emit(loadOp);
				paramTypes[i] = paramType;
			}

			// 2) load fn pointer
			il.Emit(OpCodes.Ldarg_0);
			// 3) emit the unmanaged cdecl calli
			il.EmitCalli(
				OpCodes.Calli,
				CallingConvention.Cdecl,
				returnType,
				paramTypes);
			il.Emit(OpCodes.Ret);
			return dm.CreateDelegate(delegateType);
		}
	}
}
