class PartialBlock

  attr_accessor :lista_tipos_parametros, :bloque

  def initialize (lista_tipos_parametros,&bloque)
    if(lista_tipos_parametros.size==bloque.arity)
      @lista_tipos_parametros=lista_tipos_parametros
      @bloque=bloque
    else
      raise(ArgumentError)#como hacemos? hacemos nosotros una excepcion o le pasamos por parametro un titulo y mensaje
    end
  end

  def lista_tipos_parametros
    @lista_tipos_parametros = @lista_tipos_parametros || []
  end

  def matches (*lista_parametros)
    @matchea= true
    if (self.lista_tipos_parametros.length.equal? lista_parametros.length)

      lista_parametros.each_index do |index| if not (lista_parametros[index].is_a? self.lista_tipos_parametros[index])
                                                        @matchea=false
                                             end
                                  end
    else
      @matchea = false
    end
    @matchea
  end

end