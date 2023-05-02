defmodule PokerPlanWeb.Pow.Mailer do
  use Pow.Phoenix.Mailer
  use Swoosh.Mailer, otp_app: :poker_plan

  import Swoosh.Email

  require Logger

  def cast(%{user: user, subject: subject, text: text, html: html, assigns: _assigns}) do
    # Build email struct to be used in `process/1`
    %Swoosh.Email{}
    |> to({"", user.email})
    |> from({"My App", "myapp@example.com"})
    |> subject(subject)
    |> html_body(html)
    |> text_body(text)

    # %{to: user.email, subject: subject, text: text, html: html}
  end

  def process(email) do
    # Send email
    Task.start(fn ->
      email
      |> deliver()
      |> log_warnings()
    end)

    :ok
    # to be used in dev
    # Logger.debug("E-mail sent: #{inspect(email)}")
  end

  defp log_warnings({:error, reason}) do
    Logger.warn("Mailer backend failed with: #{inspect(reason)}")
  end

  defp log_warnings({:ok, response}), do: {:ok, response}
end
