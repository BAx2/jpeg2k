from Dwt import *
import numpy as np

def Compare(text, input, restore):
    result = np.sum(np.abs(restore - input) > 1e-6) == 0
    print(text, result)
    return result

def main1():
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

    input3 = input2.T
    output3 = Dwt1D(dir = 'col', bufferSize=2, expand='leftRight', transposeAfterExpand=True)(input3)
    restore3 = Dwt1D(dir = 'col', bufferSize=2, expand='leftRight', type='backward', 
                     transposeAfterExpand=True, inputTranspose=True, transposeBeforeCrop=True)(output3)

    testsPassed = True
    testsPassed = testsPassed and Compare('Row restored:  ', input, restore)
    testsPassed = testsPassed and Compare('Col eq row:    ', output, output2[:, 0])
    testsPassed = testsPassed and Compare('Col restored:  ', input2, restore2)
    testsPassed = testsPassed and Compare('Col buff = 2:  ', input3, restore3)
    

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
    return testsPassed

def main2():
    # 2D using 1D dwt
    input2d = np.array(((-0.39063, 0.00781, 0.50000, 0.30469, -0.22656, 0.19531, -0.17188, 0.43359)), ndmin=2)
    input2d = input2d * input2d.T
    (_, width) = input2d.shape

    dwtCol  = Dwt1D(dir = 'col', bufferSize=width, expand='upDown')
    dwtRow  = Dwt1D(dir = 'col', bufferSize=2, expand='leftRight', transposeAfterExpand=True)
    
    idwtRow = Dwt1D(dir = 'col', bufferSize=2, expand='leftRight', type='backward', 
                    transposeAfterExpand=True, inputTranspose=True, transposeBeforeCrop=True)        
    idwtCol = Dwt1D(dir = 'col', type='backward', bufferSize=width, expand='upDown')

    output2dCol = dwtCol(input2d)
    restored2dCol = idwtCol(output2dCol)

    output2dRow = dwtRow(output2dCol)
    restored2dRow = idwtRow(output2dRow)

    restored2dFull = idwtCol(restored2dRow)

    testsPassed = True
    testsPassed = testsPassed and Compare('Col 2D restore: ', input2d, restored2dCol)
    testsPassed = testsPassed and Compare('Row 2D restore: ', output2dCol, restored2dRow)
    testsPassed = testsPassed and Compare('Full 2D restore:', input2d, restored2dFull)
    return testsPassed

def main3():
    input2d = np.array(((-0.39063, 0.00781, 0.50000, 0.30469, -0.22656, 0.19531, -0.17188, 0.43359)), ndmin=2)
    input2d = input2d * input2d.T
    (_, width) = input2d.shape

    dwt  = Dwt2D(type = 'forward', lineSize=width)
    dwt2 = Dwt2D(type = 'forward', lineSize=width, scaleOnFinalStage=True)
    idwt = Dwt2D(type = 'backward', lineSize=width)

    coeff = dwt(input2d)
    coeff2 = dwt2(input2d)
    restored = idwt(coeff)

    return Compare('Full 2D restore:   ', input2d, restored) \
       and Compare('Final output scale:', coeff, coeff2) 
    
def DataForTestProcessingUnit():
    sideSize = 16
    expandSize = 2
    np.random.seed(0)
    # input = np.random.rand(sideSize, sideSize)
    input = np.diag(np.random.rand(sideSize))

    print(input)
    input = np.pad(input, expandSize, 'reflect')[:, expandSize:-expandSize]
    output = np.zeros(input.shape)

    consts = Constants()
    pu = ProcessorUnit(1/consts.alpha, 
                      1/(consts.alpha * consts.beta) + 1, 
                      sideSize)

    (y, x) = input.shape
    for row in range(0, y, 2):
        for col in range(x):
            pair = Pair(input[row, col], input[row+1, col])
            pair = pu(pair)
            output[row, col] = pair.even
            output[row+1, col] = pair.odd
    
    output = output[(2*expandSize):, :]
    print(output)


if __name__ == '__main__':
    
    np.set_printoptions(precision=3)
    np.set_printoptions(linewidth=100000)
    
    allTestsPassed = True
    allTestsPassed = allTestsPassed and main1()
    allTestsPassed = allTestsPassed and main2()
    allTestsPassed = allTestsPassed and main3()
    
    DataForTestProcessingUnit()

    print('All tests passed:  ', allTestsPassed)

    pass
