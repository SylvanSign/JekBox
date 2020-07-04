defmodule Game.DataMuse.Words do
  def clues(word, count \\ 1) do
    word
    |> ml()
    |> Stream.filter(fn
      %{"tags" => tags} ->
        Enum.member?(tags, "n")

      _ ->
        true
    end)
    |> Stream.reject(fn
      %{"word" => suggestion} ->
        String.contains?(suggestion, " ")
    end)
    |> Stream.reject(fn
      %{"word" => suggestion} ->
        String.jaro_distance(suggestion, word) >= 0.75
    end)
    |> Stream.take(7)
    |> Enum.shuffle()
    |> Stream.take(count)
    |> Enum.map(&(&1 |> Map.get("word") |> String.upcase()))
  end

  def guess(words) do
    words
    |> Enum.join(",")
    |> ml()
    |> Stream.filter(fn
      %{"tags" => tags} ->
        Enum.member?(tags, "n")

      _ ->
        true
    end)
    |> Stream.reject(fn
      %{"word" => suggestion} ->
        String.contains?(suggestion, " ")
    end)
    |> Enum.reject(fn
      %{"word" => suggestion} ->
        Enum.reduce(words, false, fn word, rejected? ->
          rejected? or String.jaro_distance(word, suggestion) >= 0.75
        end)
    end)
    |> hd()
    |> Map.get("word")
    |> String.upcase()
  end

  def ml(input) do
    "md=p&ml=#{input}"
    |> call()
  end

  def rel_jja(input) do
    call("rel_jja=#{input}")
  end

  def rel_jjb(input) do
    call("rel_jjb=#{input}")
  end

  def rel_syn(input) do
    call("rel_syn=#{input}")
  end

  def rel_trg(input) do
    call("rel_trg=#{input}")
  end

  def call(qs) do
    {:ok, {_, _, raw}} = :httpc.request('https://api.datamuse.com/words?#{qs}')

    Jason.decode!(raw)
  end
end
