require_relative '../src/partial_block'

module MultiMethods

  def suma(lista)#se puede agregar a la clase que corresponda en ruby
    sum = 0
    lista.each { |a| sum+=a }
    sum
  end

  def distancia_parametro_parcial(parametro,tipo_parametro)
    parametro.class.ancestors.index(tipo_parametro)
  end

  def distancia_parametro_total(lista_parametros,lista_tipos_parametro)#arreglar segun corresponda segun suma
    total =suma(lista_parametros.collect { |parametro| distancia_parametro_parcial(parametro,lista_tipos_parametro[lista_parametros.index(parametro)])*(lista_parametros.index(parametro)+1) })
  end

  def self.partial_def (nombre,lista_parametros,&bloque)
    bloque_parcial = PartialBlock.new(lista_parametros,&bloque)
    self.class.define_method(nombre, bloque_parcial)
  end

end