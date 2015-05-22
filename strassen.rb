class Matrix
  attr_reader :rows, :cols
  def initialize(rows, cols, m=nil)
    @rows, @cols = rows, cols
    @total_columns = cols
    @matrix = m || Array.new(@rows * @cols, 0)
    @sr, @sc, @er, @ec = 0, 0, 0, 0
  end

  def [](r, c)
    return nil if r >= @rows || c >= @cols
    @matrix[(r + @sr)*@total_columns + @sc + c]
  end

  def []=(r, c, v)
    return nil if r >= @rows || c >= @cols
    @matrix[(r + @sr)*@total_columns + @sc + c] = v
  end

  def submatrix(sr, sc, er, ec)
    m = dup
    m.instance_exec do
      @rows = er - sr
      @cols = ec - sc
      @sr = sr
      @sc = sc
      @er = er - 1
      @ec = ec - 1
    end
    m
  end

  def inspect
    @matrix.inspect
  end

  def + matrix
    operate :+, matrix
  end

  def - matrix
    operate :-, matrix
  end

  def * b
    if square?
      strassen(b)
    else
      multiply(b)
    end
  end

  def square?
    @rows == @cols
  end

  def strassen(b)
    c = Matrix.new(@rows, @rows)
    if @rows == 1
      c[0, 0] = self[0, 0] * b[0, 0]
      return c
    end

    h = @rows/2
    a0 = submatrix(0, 0, h, h)
    a1 = submatrix(0, h, h, @rows)
    a2 = submatrix(h, 0, @rows, h)
    a3 = submatrix(h, h, @rows, @rows)

    b0 = b.submatrix(0, 0, h, h)
    b1 = b.submatrix(0, h, h, @rows)
    b2 = b.submatrix(h, 0, @rows, h)
    b3 = b.submatrix(h, h, @rows, @rows)

    c0 = c.submatrix(0, 0, h, h)
    c1 = c.submatrix(0, h, h, @rows)
    c2 = c.submatrix(h, 0, @rows, h)
    c3 = c.submatrix(h, h, @rows, @rows)

    m1 = (a0 + a3) * (b0 + b3)
    m2 = (a2 + a3) * b0
    m3 = a0 * (b1 - b3)
    m4 = a3 * (b2 - b0)
    m5 = (a0 + a1) * b3
    m6 = (a2 - a0) * (b0 + b1)
    m7 = (a1 - a3) * (b2 + b3)

    c0 << (m1 + m4) - (m5 - m7)
    c1 << m3 + m5
    c2 << m2 + m4
    c3 << (m1 - m2) + (m3 + m6)

    return c
  end

  def multiply(matrix)
    if can_multiply?(matrix)
      m = Matrix.new(@rows, matrix.cols)
      @rows.times do |i|
        matrix.cols.times do |j|
          @cols.times do |k|
            m[i, j] += self[i, k] * matrix[k, j]
          end
        end
      end
      m
    else
      raise "Matrices are incompatible"
    end
  end

  def transpose
    t = Matrix.new(@cols, @rows)
    @cols.times do |c|
      @rows.times do |r|
        t[c, r] = self[r, c]
      end
    end
    t
  end

  def << matrix
    if same_dimensions?(matrix)
      @rows.times do |r|
        @cols.times do |c|
          self[r, c] = matrix[r, c]
        end
      end
    else
      raise "Matrices are not of the same dimensions: #{matrix}"
    end
  end

  private
  def operate(operation, matrix)
    if same_dimensions?(matrix)
      m = Matrix.new(@rows, @cols)
      @rows.times do |r|
        @cols.times do |c|
          m[r, c] = self[r, c].send operation, matrix[r, c]
        end
      end
      m
    else
      raise "Matrices are not of the same dimensions: #{inspect} vs #{matrix.inspect}"
    end
  end

  def same_dimensions?(matrix)
    matrix.rows == @rows && matrix.cols == @cols
  end

  def can_multiply?(matrix)
    @cols == matrix.rows
  end
end
