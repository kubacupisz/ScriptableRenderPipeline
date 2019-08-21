//custom-begin:

using UnityEngine;
using UnityEngine.Scripting;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;

using Debug = UnityEngine.Debug;

[AttributeUsage(AttributeTargets.Class)]
public class HDRPCallbackAttribute : PreserveAttribute {
	static public void ConfigureCallbacks(Type type) {
		var methodInfo = type.GetMethods(BindingFlags.Static|BindingFlags.NonPublic|BindingFlags.Public)
			.Where(mi => mi.GetCustomAttributes(typeof(HDRPCallbackMethodAttribute), false).Length > 0).FirstOrDefault();

		if(methodInfo != null)
			methodInfo.Invoke(null, null);
	}

	static public void ConfigureCallbacks(IEnumerable<Type> types) {
		foreach(var type in types)
            if (type != null)
                ConfigureCallbacks(type);
	}

	static public void ConfigureAllLoadedCallbacks() {
		foreach(var assembly in AppDomain.CurrentDomain.GetAssemblies()) {
            Type[] types = null;

            try {
                types = assembly.GetTypes();
            } catch (ReflectionTypeLoadException e) {
                Debug.LogWarning(
                    $"HDRPCallback: {e.Message}: " +
                    e.LoaderExceptions.Select(x => x.Message).Aggregate((x, y) => $"{x}; {y}"));
                types = e.Types;
            }

            if (types != null)
                ConfigureCallbacks(types);
        }
	}
}

[AttributeUsage(AttributeTargets.Method)]
public class HDRPCallbackMethodAttribute : PreserveAttribute {}

//custom-end:
