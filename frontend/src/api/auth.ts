import { apiRequest } from "@/lib/api";

export type AuthSuccess = {
  data: {
    access_token: string;
    renewal_token: string;
    user: { id: string; email: string };
  };
};

export async function registerUser(body: {
  user: {
    email: string;
    password: string;
    password_confirmation: string;
  };
}): Promise<AuthSuccess> {
  return apiRequest<AuthSuccess>("/api/v1/registration", {
    method: "POST",
    json: body,
  });
}

export async function signIn(body: {
  user: { email: string; password: string };
}): Promise<AuthSuccess> {
  return apiRequest<AuthSuccess>("/api/v1/session", {
    method: "POST",
    json: body,
  });
}

export async function requestPasswordReset(email: string): Promise<{
  data: { message: string };
}> {
  return apiRequest("/api/v1/password-reset", {
    method: "POST",
    json: { email },
  });
}

export async function resetPassword(body: {
  token: string;
  password: string;
  password_confirmation: string;
}): Promise<{ data: { message: string } }> {
  return apiRequest("/api/v1/password-reset", {
    method: "PUT",
    json: body,
  });
}
