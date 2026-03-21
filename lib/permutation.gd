class_name Permutation

static func Factorial(n: int) -> int:
	if n <= 1:
		return 1
	var result := 1
	for i in range(2, n + 1):
		result *= i
	return result

# GDScript function to unrank a permutation
# rank: The index of the permutation (0 to n!-1)
static func Unrank(src_array :Array, rank: int) -> Array:
	var work_array := src_array.duplicate()
	var result_array := []
	var fact := Factorial(work_array.size()-1)
	for i in range(work_array.size() - 1, -1, -1):
		var index := rank / fact
		rank = rank % fact
		result_array.append(work_array[index])
		work_array.remove_at(index)
		if i > 0:
			fact /= i
	return result_array


# Main function to get all permutations as an array of arrays
static func SlowRecursive(array :Array) -> Array:
	var output :Array = []
	_slow_recursive_helper(array, 0, output)
	return output

# Recursive helper function
static func _slow_recursive_helper(array :Array, start_index :int, output :Array) -> void:
	if start_index == array.size():
		# Base case: a complete permutation is found, add it to the output
		# Use .duplicate(true) to ensure a deep copy if elements are complex objects/arrays
		output.append(array.duplicate())
		return

	for i :int in range(start_index, array.size()):
		# Swap current element with the element at the start index
		var tmp = array[start_index]
		array[start_index] = array[i]
		array[i] = tmp

		# Recurse for the next index
		_slow_recursive_helper(array, start_index + 1, output)

		# Backtrack: swap them back to restore the original array state for the next iteration
		array[i] = array[start_index]
		array[start_index] = tmp

static func SlowRecursivePackedByte(array :PackedByteArray) -> Array:
	var output :Array = []
	_slow_recursive_pbyte_helper(array, 0, output)
	return output

static func _slow_recursive_pbyte_helper(array :PackedByteArray, start_index :int, output :Array) -> void:
	if start_index == array.size():
		output.append(array.duplicate())
		return
	for i :int in range(start_index, array.size()):
		var tmp := array[start_index]
		array[start_index] = array[i]
		array[i] = tmp
		_slow_recursive_pbyte_helper(array, start_index + 1, output)
		array[i] = array[start_index]
		array[start_index] = tmp

static func HeapRecursive(array :Array) -> Array:
	var output :Array = []
	_array_heap_helper(array, array.size(), output)
	return output

static func _array_heap_helper(array :Array, k :int, output :Array) -> void:
	if k == 1 :
		output.append(array.duplicate())
		return
	_array_heap_helper(array, k-1, output)
	for i in k-1:
		if k % 2 == 0: # swap array[i] array[k-1]
			var tmp = array[i]
			array[i] = array[k-1]
			array[k-1] = tmp
		else : # swap array[0] array[k-1]
			var tmp = array[0]
			array[0] = array[k-1]
			array[k-1] = tmp
		_array_heap_helper(array, k-1, output)

static func HeapLoop(array :Array) -> Array:
	var output :Array = [array.duplicate()]
	var c :Array[int] = []
	c.resize(array.size())
	for i in array.size():
		c[i] = 0
	var i := 1
	while i < array.size():
		if c[i] < i:
			if i % 2 == 0: # swap array[0] array[i]
				var tmp = array[0]
				array[0] = array[i]
				array[i] = tmp
			else : # swap array[ c[i] ] array[i]
				var tmp = array[c[i]]
				array[c[i]] = array[i]
				array[i] = tmp
			output.append(array.duplicate())
			c[i] += 1
			i =1
		else:
			c[i] = 0
			i += 1
	return output

#// i acts similarly to a stack pointer
	#i := 1;
	#while i < n do
		#if  c[i] < i then
			#if i is even then
				#swap(A[0], A[i])
			#else
				#swap(A[c[i]], A[i])
			#end if
			#output(A)
			#// Swap has occurred ending the while-loop. Simulate the increment of the while-loop counter
			#c[i] += 1
			#// Simulate recursive call reaching the base case by bringing the pointer to the base case analog in the array
			#i := 1
		#else
			#// Calling permutations(i+1, A) has ended as the while-loop terminated. Reset the state and simulate popping the stack by incrementing the pointer.
			#c[i] := 0
			#i += 1
		#end if
	#end while
