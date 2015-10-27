# FEN - Forsyth-Edwards Notation   
# https://en.wikipedia.org/wiki/Forsyth-Edwards_Notation

# PGN - Portable Game Notation
# https://en.wikipedia.org/wiki/Portable_Game_Notation

# SAN - Standard Algebraic Notation
# https://en.wikipedia.org/wiki/Algebraic_notation_(chess)

# https://en.wikipedia.org/wiki/Promotion_(chess)
# https://en.wikipedia.org/wiki/Fifty-move_rule

# Board ary:                        col
#                           0 1 2 3 4 5 6 7 8 9
#                       0   - - - - - - - - - -
#                       1   - - - - - - - - - -
#                       2   - r n b q k b n r -  8
#                       3   - p p p p p p p p -  7
#                     r 4   - - - - - - - - - -  6 r
#                     o 5   - - - - - - - - - -  5 a
#                     w 6   - - - - - - - - - -  4 n
#                       7   - - - - - - - - - -  3 k
#                       8   - P P P P P P P P -  2
#                       9   - R N B Q K B N R -  1
#                      10   - - - - - - - - - -
#                      11   - - - - - - - - - -
#                             a b c d e f g h
#                                  file



class String
  def to_idx
    ('8'.ord - self[1].ord + 2)*10 + (self[0].ord - 'a'.ord + 1)
  end
end

class Symbol
  def white?
    self == self.upcase
  end
  def pawn?
    self == :p || self == :P
  end
  def king?
    self == :k || self == :K
  end
end

class Fixnum
  def to_sq
    (self%10 + 'a'.ord - 1 ).chr + ('8'.ord - `Math.floor(self/10)` +2).chr
  end
end

class Array
  def to_idx
    self[0] + 1 + (self[1] +2)*10
  end
end


module ChessHelper
  ('a'..'h').each_with_index do |file,x|
    (1..8).each_with_index do |rank,y|
      define_method("#{file}#{rank}".to_sym) {
        (8 -y +1)*10 + x + 1
      }
    end
  end
end

class Position
  include ChessHelper
  INITIAL = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
  PIECES = {
      true => [:R,:N,:B,:Q,:K,:P],
      false  =>  [:r, :n, :b, :q, :k, :p]
  }
  PROMOTE = {
      true => [:Q,:N,:R,:B],
      false => [:q,:n,:r,:b]
  }
  HALF_MOVES_LIMIT = 50

  attr_accessor :board, :white, :castling, :en_passant, :half_move, :full_move
  attr_reader :king_idx

  def self.fen(fen)
    new.tap do |pos|
      # add  moves counters if omited
      fen += ' 0 1' if fen.split.size == 4 
      raise ArgumentError unless fen.split.size == 6
      bo,tu,ca,ep,hm,fm =fen.split
      raise ArgumentError unless
          tu[/^[bw]$/] && ca[/^(([kqKQ]+)|(-))$/] &&
              ep[ /^(([a-h][1-8])|(\-))$/ ] &&
              hm[/^\d+$/] && fm[/^\d+$/]

      pos.board = bo.split('/').each_with_index.flat_map {|row, i|
        row = row.gsub(/\d/) {|m| '-'*m.to_i}.chars.map(&:to_sym).unshift(nil).push(nil)
        raise ArgumentError, "Invalid FEN string: error in row #{i}" unless row.size ==  10
        row
      }.map {|i| i == :- ? nil : i}

      pos.board.unshift(*[nil]*20).push(*[nil]*20)
      raise ArgumentError, "Invalid FEN string: number of rows must equal 8" unless pos.board.size == 120

      pos.white = tu == 'w'
      pos.castling = ca == '-' ? '' : ca
      pos.en_passant = ep == '-' ? nil : ep.to_idx
      pos.half_move = hm.to_i
      pos.full_move = fm.to_i

      pos.memoize_kings_positions!

    end
  end

  def self.empty               
    new
  end

  def self.initial
    fen(INITIAL)
  end

  def self.[](**args)
    new.tap do |pos|
      args.each {|piece,coords|
        next unless  piece.size == 1
        coords = [coords] unless coords.instance_of? Array
        coords.each {|coord|
          pos.board[coord] = piece
        }
      }
      pos.white      = args[:turn] != :b
      pos.castling   = args[:castling] if args[:castling]
      pos.en_passant = args[:en_passant] if args[:en_passant]
      pos.half_move  = args[:half_move] if args[:half_move]
      pos.full_move  = args[:full_move] if args[:full_move]
      pos.memoize_kings_positions!
    end
  end

  private_class_method :new
  def initialize()
    @board       = [nil]*120
    @white       = true # move turn  
    @castling    = ''
    @en_passant  = nil
    @half_move   = 0
    @full_move   = 1
    memoize_kings_positions!
  end

  def initialize_copy(o)
    @board       = o.board.dup
    @castling    = o.castling.dup
    @king_idx    = o.king_idx.dup
  end

  def ==(other)
    self.class == other.class  &&
        @board      == other.board      &&
        @white       == other.white       &&
        @castling   == other.castling   &&
        @en_passant == other.en_passant &&
        @half_move  == other.half_move  &&
        @full_move  == other.full_move
  end

  def ===(fen_str)
    fen_str.class == String && to_fen == fen_str
  end

  def to_fen
    b = @board.each_slice(10).to_a[2..9].map {|row|
      row[1..8].map{|s|s||'-'}.join.gsub(/-+/){|empty| empty.size}
    }.join '/'
    ep = (@en_passant.to_sq if @en_passant) || '-'
    ca = @castling.empty? ?  '-' : @castling
    "#{b} #{@white?'w':'b' } #{ca} #{ep} #@half_move #@full_move"
  end
  alias_method :inspect, :to_fen
  def to_s
    b = @board.each_slice(10).to_a[2..9].map {|row| row[1..8].map{|s| s || '-'}.join(' ')}.join("\n")
    ep = (@en_passant.to_sq if @en_passant) || '-'
    ca = @castling.empty? ?  '-' : @castling
    "#{b} #{@white?'w':'b' } #{ca} #{ep} #@half_move #@full_move"
  end

  def in_check?
    return false unless @king_idx[@white]
    under_attack?(@king_idx[@white])
  end

  def under_attack?(to)
    PIECES[!@white].any? do |piece|
      find_from_for(piece, to: to ).any?
    end
  end


  def filter_moves_in_check(moves)
    moves.select do |from,to, promote|

      # cant castle from check
      next if (from - to).abs == 2 && @board[from].king? && in_check?

      # look ahead not in check
      ahead = dup
      ahead.move!(from,to,promote, transition: false)
      ! ahead.in_check?
    end

  end


  def move!(from,to,promote =  nil, options = {transition: true})

    transition =  options[:transition]

    piece = @board[from]
    is_ep_capture = piece.pawn? && to == @en_passant
    is_capture = true if @board[to] || is_ep_capture

    ###
    ### piece move 
    ###
    @board[to] = promote ||  @board[from]
    @board[from] = nil
    @board[@en_passant+(@white?10:-10)] = nil if is_ep_capture

    if piece.king?
      @king_idx[@white] = to

      # move rook after king on castling
      if (to-from) == 2
        @board[(@white ? f1 : f8)] = @board[(@white ? h1 : h8)]
        @board[(@white ? h1 : h8)] = nil
      elsif (to-from) == -2
        @board[(@white ? d1 : d8)] = @board[(@white ? a1 : a8)]
        @board[(@white ? a1 : a8)] = nil
      end
    end
    ###

    return unless transition

    ###
    ### update position for transition  to next move
    ###
    lost_castling = ''
    lost_castling += 'K' if from == h1 || to == h1
    lost_castling += 'k' if from == h8 || to == h8
    lost_castling += 'Q' if from == a1 || to == a1
    lost_castling += 'q' if from == a8 || to == a8
    lost_castling += (@white ? 'KQ' : 'kq') if from == (@white ? e1 : e8)
    @castling = @castling.delete lost_castling

    @en_passant = piece.pawn? && ((to-from) == (@white ? -20 : 20)) ? `Math.floor((to+from)/2)` : nil

    if piece.pawn? || is_capture
      @half_move = 0
    else
      @half_move += 1
    end

    @full_move += 1 if !@white  # count fullmove after move of black
    @white ^= true              # and toggle next move turn

    self
  end

  def find_from_for(piece, to:)
    color = piece.white?
    return [] if @board[to] && @board[to].white? == color # no capture own pieces 
    case piece
      when :R, :r
        find_path(piece, to: to, directions:[-10,-1,1,10], long: true)
      when :N, :n
        find_path(piece, to: to, directions:[-21,-19,-12,-8,8,12,19,21], long: false)
      when :B, :b
        find_path(piece, to: to, directions:[-11,-9,9,11], long: true)
      when :Q, :q
        find_path(piece, to: to, directions:[-11,-10,-9,-1,1,9,10,11], long: true)
      when :K, :k
        res = find_path(piece, to: to, directions:[-11,-10,-9,-1,1,9,10,11], long: false)

        # castling
        if @board[to].nil?
          king_from = king_idx[color]
          # from initial position by 2 squares left or right
          if  king_from == (color ? e1 : e8) && (to - king_from).abs == 2
            # king side
            if to == (color ? g1 : g8) && @castling.include?((color ? 'K':'k'))
              res.push king_from unless @board[(color ? f1 : f8)] || # path is clear
                  # no castling THROUGH check and INTO  check
                  under_attack?((color ? f1 : f8)) || under_attack?((color ? g1 : g8))
              # queen side
            elsif to == (color ? c1 : c8) && @castling.include?((color ? 'Q':'q'))
              res.push king_from unless @board[(color ? d1 : d8)] || @board[(color ? b1 : b8)] ||
                  under_attack?(color ? d1 : d8) || under_attack?(color ? c1 : c8)
            end
          end
        end
        res
      when :P, :p
        res = []
        if @board[to] || to == @en_passant  # capture
          [11,9].each { |dir|
            from = to + (color ? dir : -dir)
            res.push from  if @board[from] == piece
          }
        else # no capture 
          from1 = to + (color ? 10 : -10)
          res.push from1 if @board[from1] == piece
          from2 = to + (color ? 20 : -20)
          res.push from2 if @board[from2] == piece &&
              `Math.floor(to/10)` == (color ? 6 : 5) && ! @board[from1] # double move & path is clear

        end
        res
    end
  end

  def find_path(piece, to:, directions:[], long: false)
    res = []
    directions.each do |dir|
      if long
        from = to + dir
        while from.between?(21,98) && (from%10).between?(1,8)
          res.push from if @board[from] == piece
          break if @board[from]
          from += dir
        end
      else
        from = to+dir
        res.push from if @board[from] == piece
      end
    end
    res
  end

  def memoize_kings_positions!
    @king_idx = {
        true => @board.index(:K),
        false  => @board.index(:k)
    }
  end

  def move_to_san(from, to, promote = nil)
    piece = @board[from]
    if piece.king? && to - from == 2
      'O-O'
    elsif piece.king? && to - from == -2
      'O-O-O'
    else
      piece_str = piece.pawn? ? '' : piece.to_s.upcase
      promote_str = promote ? "=#{promote.upcase}" : ""
      is_capture = board[to] || piece.pawn? && to == @en_passant
      capture_str = is_capture ? 'x' : ''
      froms = find_from_for(piece, to: to)
      pawn_file_str = piece.pawn? && is_capture ? from.to_sq[0] : ''

      if froms.size == 1
        "#{piece_str}#{pawn_file_str}#{capture_str}#{to.to_sq}#{promote_str}"
      elsif froms.select{|idx| idx%10 == from%10}.size == 1
        "#{piece_str}#{from.to_sq[0]}#{pawn_file_str}#{capture_str}#{to.to_sq}#{promote_str}"
      elsif froms.select{|idx| `Math.floor(idx/10)` == `Math.floor(from/10)`}.size == 1
        "#{piece_str}#{from.to_sq[1]}#{pawn_file_str}#{capture_str}#{to.to_sq}#{promote_str}"
      else
        "#{piece_str}#{from.to_sq}#{pawn_file_str}#{capture_str}#{to.to_sq}#{promote_str}"
      end
    end
  end

  def possible_moves
    moves = []

    (0..7).each{|row|(0..7).each{|col|
      to = (row+2)*10 + col+1
      PIECES[@white].each do |piece|
        froms = find_from_for(piece, to: to)
        froms.each {|from|

          if piece.pawn? && `Math.floor(to/10)` == (@white ? 2 : 9) #promotion 
            moves.push  *PROMOTE[@white].map{|promote| [from,to,promote]}
          else
            moves.push [from,to]
          end

        }
      end
    }}

    # must get out of check & cant move into check
    filter_moves_in_check moves
  end
  def possible_moves_str
    possible_moves.map{|from,to,promote| move_to_san(from,to,promote)}.sort
  end

  def checkmate?
    in_check? && possible_moves.empty?
  end
  def stalemate?
    !in_check? && possible_moves.empty?
  end
  def draw?
    stalemate? || !checkmate? && @half_move >= HALF_MOVES_LIMIT
  end
  def game_end?
    possible_moves.empty? || @half_move >= HALF_MOVES_LIMIT
  end


end                                                 



      