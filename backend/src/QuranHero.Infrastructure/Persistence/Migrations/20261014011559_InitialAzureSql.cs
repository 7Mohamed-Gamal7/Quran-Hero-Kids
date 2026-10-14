using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuranHero.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class InitialAzureSql : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "child_profiles",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    OwnerUid = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    AgeBand = table.Column<string>(type: "nvarchar(8)", maxLength: 8, nullable: true),
                    IsArchived = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_child_profiles", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "study_sessions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ChildId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ClientEventId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Kind = table.Column<string>(type: "nvarchar(24)", maxLength: 24, nullable: false),
                    DurationSeconds = table.Column<int>(type: "int", nullable: false),
                    OccurredAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ReceivedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_study_sessions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_study_sessions_child_profiles_ChildId",
                        column: x => x.ChildId,
                        principalTable: "child_profiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_child_profiles_OwnerUid_IsArchived",
                table: "child_profiles",
                columns: new[] { "OwnerUid", "IsArchived" });

            migrationBuilder.CreateIndex(
                name: "IX_study_sessions_ChildId_ClientEventId",
                table: "study_sessions",
                columns: new[] { "ChildId", "ClientEventId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_study_sessions_ChildId_OccurredAt",
                table: "study_sessions",
                columns: new[] { "ChildId", "OccurredAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "study_sessions");

            migrationBuilder.DropTable(
                name: "child_profiles");
        }
    }
}
