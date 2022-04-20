from Dwt import *
import numpy as np

def main():
    def Compare(text, input, restore):
        result = np.sum(np.abs(restore - input) > 1e-6) == 0
        print(text, result)
        return result

    input = np.array(((-0.39063, 0.00781, 0.50000, 0.30469, -0.22656, 0.19531, -0.17188, 0.43359)), ndmin=2)

    # row test
    dwt = Dwt1D()
    idwt = Dwt1D(type='backward')
    output = dwt(input)
    restore = idwt(output)

    # col test
    input2 = np.concatenate((input.T, np.zeros(input.T.shape)), axis=1)
    dwt = Dwt1D(dir = 'col', bufferSize = 2, expand='upDown')
    output2 = dwt(input2)
    idwt = Dwt1D(dir = 'col', type='backward', bufferSize = 2, expand='upDown')
    restore2 = idwt(output2)

    testsPassed = True
    testsPassed = testsPassed and Compare('Row restored:  ', input, restore)
    testsPassed = testsPassed and Compare('Col eq row:    ', output, output2[:, 0])
    testsPassed = testsPassed and Compare('Col restored:  ', input2, restore2)
    

    matrix = np.array((
        (1,  0, 2,  0, 3,  0, 4 , 0),
        (0,  1,  0, 2,  0, 3,  0, 4),
        (5,  0, 6,  0, 7,  0, 8 , 0),
        (0,  5,  0, 6,  0, 7,  0, 8),
        (9,  0, 10, 0, 11, 0, 12, 0),
        (0,  9,  0, 10, 0, 11, 0, 12),
        (13, 0, 14, 0, 15, 0, 16, 0),
        (0, 13, 0, 14, 0, 15, 0, 16),
    ))
    testsPassed = testsPassed and Compare('Matrix reorder:', matrix, Dwt2D().IReorder(Dwt2D().Reorder(matrix)))
    

    # sideSize = 8
    # np.random.seed(0)
    # matrix = np.random.rand(sideSize, sideSize) - 0.5
    # dwt2 = Dwt2D(type='forward', lineSize=sideSize)
    # idwt2 = Dwt2D(type='backward', lineSize=sideSize)
    # coeff = dwt2(matrix)
    # restored = idwt2(coeff)
    # testsPassed = testsPassed and Compare('2D restored:   ', matrix, restored)

    # print('--------------------------------------------------')
    # print(matrix)
    # print('--------------------------------------------------')
    # print(restored)
    # print('--------------------------------------------------')
    
    input3 = input2.T
    output3 = Dwt1D(dir = 'col', bufferSize=2, expand='leftRight', transposeAfterExpand=True)(input3)
    output3 = Dwt2D().Transpose(output3)
    restore3 = Dwt1D(dir = 'col', bufferSize=2, expand='leftRight', type='backward', transposeAfterExpand=True)(output3)

    print(input3)
    print(output3)
    print(Dwt2D().Transpose(restore3))

    # print(output2.T[0, :])
    # print(Dwt2D().Transpose(output3)[0, :])
    # print(Dwt2D().Transpose(output3)[0, :] - output2.T[0, :])

    # print('--------------------------------------------------')
    # print(Dwt2D().Transpose(Dwt1D(dir = 'col', bufferSize=2, type='backward', expand='leftRight')(output3)))

    print('Tests passed:  ', testsPassed)



if __name__ == '__main__':
    main()

    pass
