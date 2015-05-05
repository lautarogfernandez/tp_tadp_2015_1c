class PartialBlock

  attr_accessor :lista_tipos_parametros, :bloque

  def coincide_aridad_entre_argumentos_y_parametros?(lista_tipos_parametros, argumentos)
    lista_tipos_parametros.size==argumentos.size
  end

  def initialize (lista_tipos_parametros,&bloque)
    if(coincide_aridad_entre_argumentos_y_parametros?(lista_tipos_parametros, bloque.parameters))
      @lista_tipos_parametros=lista_tipos_parametros
      @bloque=bloque
    else
      raise(ArgumentError)#como hacemos? hacemos nosotros una excepcion o le pasamos por parametro un titulo y mensaje
    end
  end

  def matches(*argumentos)
    if coincide_aridad_entre_argumentos_y_parametros?(@lista_tipos_parametros,argumentos)
      matchea = @lista_tipos_parametros.zip(argumentos).all? do |tipo_parametro, argumento|
        argumento.is_a? tipo_parametro
      end
    end
    matchea || false
  end

  def matches_tipos(lista_tipos)
    if coincide_aridad_entre_argumentos_y_parametros?(@lista_tipos_parametros,lista_tipos)
      matchea = @lista_tipos_parametros.zip(lista_tipos).all? do |tipo_parametro, tipo|
        tipo.ancestors.include?(tipo_parametro)
      end
    end
    matchea || false
  end


  def call(*argumentos)
    if(self.matches(*argumentos))
      self.bloque.call(*argumentos)
    else
      raise(ArgumentError)#como hacemos? hacemos nosotros una excepcion o le pasamos por parametro un titulo y mensaje
    end
  end

  def call_with_binding(*argumentos, new_self)
    # no me gusta de usar call_with_binding que abre la posibilidad de ejecutar el partial block sin el mathchs.
    # El tema uqe para solucionarlo habria que usar el matches adentro dle nuevo call_with_binding (llamandose 2 veces al matches)

    new_self.instance_exec *argumentos, &bloque
  end

end