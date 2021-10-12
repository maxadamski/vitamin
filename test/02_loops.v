
test "break out of infinite loop"
    print('before loop')
    while true
        print('inside loop')
        break
    print('after loop')

test "break out of nested loop"
    print('before outer loop')
    while true
        print('inside outer loop')
        while true
            print('inside inner loop')
            break
        print('after inner loop')
        break
    print('after outer loop')
